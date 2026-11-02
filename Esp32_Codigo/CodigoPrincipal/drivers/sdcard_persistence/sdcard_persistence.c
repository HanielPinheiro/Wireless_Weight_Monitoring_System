#include "../../config/config.h"

static const char *ROTULO_LOCAL = "PW_PERSIST";
static const char *BOOT_NAMESPACE = "boot_meta";
static const char *BOOT_REASON_KEY = "last_reset";

system_state_t g_sys = {0};

static uint32_t sequence_id = 0;
static esp_reset_reason_t boot_reason = 0;
static int64_t boot_epoch = 0;

static pw_outbox_entry_t s_ram_buf[PW_RAM_BUFFER_SLOTS];
static size_t s_ram_head = 0;
static size_t s_ram_tail = 0;
static size_t s_ram_count = 0;

static esp_err_t pw_boot_nvs_open(nvs_handle_t *out)
{
    if (nvs_open(BOOT_NAMESPACE, NVS_READWRITE, out) != ESP_OK)
        return ESP_FAIL;
    return ESP_OK;
}

int64_t pw_safe_epoch(void)
{
    if (g_sys.datetime_synced)
    {
        time_t now = 0;
        time(&now);
        return (int64_t)now;
    }
    TickType_t diff = xTaskGetTickCount() - g_sys.boot_tick;
    return (int64_t)(diff / configTICK_RATE_HZ);
}

static esp_err_t pw_store_sequence_id(void)
{
    if (!g_sys.sd_ok)
        return ESP_OK;
    char seq_str[24] = {0};
    snprintf(seq_str, sizeof(seq_str), "%lu", (unsigned long)sequence_id);
    return sdcard_overwrite_file(SEQUENCE_FILE, seq_str);
}

static esp_err_t pw_load_sequence_id(void)
{
    struct stat st = {0};
    if (stat(SEQUENCE_FILE, &st) != 0)
    {
        sequence_id = 0;
        return pw_store_sequence_id();
    }

    FILE *file = fopen(SEQUENCE_FILE, "r");
    if (file == NULL)
        return ESP_FAIL;

    char seq_str[24] = {0};
    if (fgets(seq_str, sizeof(seq_str), file) == NULL)
        sequence_id = 0;
    else
        sequence_id = (uint32_t)strtoul(seq_str, NULL, 10);

    fclose(file);
    return ESP_OK;
}

esp_err_t sdcard_persistence_init(void)
{
    if (!g_sys.sd_ok)
    {
        sequence_id = 0;
        ESP_LOGW(ROTULO_LOCAL, "SD indisponivel. Sequence ID em RAM apenas (inicia em 0)");
        return ESP_OK;
    }
    esp_err_t err = pw_load_sequence_id();
    if (err != ESP_OK)
        return err;

    ESP_LOGI(ROTULO_LOCAL, "Sequence ID carregado do SD: %lu", (unsigned long)sequence_id);
    return ESP_OK;
}

uint32_t pw_current_sequence_id(void)
{
    return sequence_id;
}

uint32_t pw_next_sequence_id(void)
{
    sequence_id++;
    if (pw_store_sequence_id() != ESP_OK)
        ESP_LOGW(ROTULO_LOCAL, "Sequence ID nao persistido (SD down).");
    return sequence_id;
}

esp_err_t pw_save_reset_reason_nvs(esp_reset_reason_t reason)
{
    nvs_handle_t h = 0;
    if (pw_boot_nvs_open(&h) != ESP_OK)
        return ESP_FAIL;

    esp_err_t err = nvs_set_i32(h, BOOT_REASON_KEY, (int32_t)reason);
    if (err == ESP_OK)
        err = nvs_commit(h);

    nvs_close(h);
    return err;
}

static const char *pw_sev_to_str(pw_severity_t sev)
{
    switch (sev)
    {
    case PW_SEV_INFO:
        return "INFO";
    case PW_SEV_WARN:
        return "WARN";
    case PW_SEV_ERROR:
        return "ERROR";
    case PW_SEV_CRITICAL:
        return "CRITICAL";
    default:
        return "INFO";
    }
}

esp_err_t pw_rotate_if_needed(const char *path, size_t max_size_bytes, uint8_t keep_versions)
{
    if (!g_sys.sd_ok)
        return ESP_OK;
    if (max_size_bytes == 0 || keep_versions == 0)
        return ESP_OK;

    struct stat st = {0};
    if (stat(path, &st) != 0)
        return ESP_OK;
    if ((size_t)st.st_size < max_size_bytes)
        return ESP_OK;

    char src[96] = {0};
    char dst[96] = {0};

    snprintf(dst, sizeof(dst), "%s.%d", path, keep_versions);
    remove(dst);

    for (int i = (int)keep_versions - 1; i >= 1; i--)
    {
        snprintf(src, sizeof(src), "%s.%d", path, i);
        snprintf(dst, sizeof(dst), "%s.%d", path, i + 1);
        rename(src, dst);
    }

    snprintf(dst, sizeof(dst), "%s.1", path);
    rename(path, dst);
    return sdcard_overwrite_file(path, "");
}

static esp_err_t pw_append_line(const char *path, size_t max_size, uint8_t keep_versions, const char *line)
{
    if (!g_sys.sd_ok)
        return ESP_OK;
    (void)pw_rotate_if_needed(path, max_size, keep_versions);
    return sdcard_write_file((char *)path, (char *)line);
}

esp_err_t pw_log_event(pw_severity_t sev, const char *event_type, const char *origin, const char *msg)
{
    uint32_t seq = pw_next_sequence_id();
    int64_t now = pw_safe_epoch();

    char line[320] = {0};
    snprintf(line, sizeof(line), "EVT|%lu|%lld|%s|%s|%s|%s",
             (unsigned long)seq, (long long)now, pw_sev_to_str(sev),
             event_type ? event_type : "", origin ? origin : "", msg ? msg : "");

    esp_err_t ret = pw_append_line(AUDIT_FILE, 128 * 1024, 3, line);
    if (sev == PW_SEV_CRITICAL)
        pw_append_line(CRITICAL_FILE, 64 * 1024, 3, line);

    if (!g_sys.sd_ok)
        ESP_LOGW(ROTULO_LOCAL, "SD down. Evento [%s] nao persistido: %s", event_type ? event_type : "?", msg ? msg : "");
    return ret;
}

esp_err_t pw_log_command(uint32_t cmd_seq, const char *command_payload)
{
    int64_t now = pw_safe_epoch();
    char line[320] = {0};
    snprintf(line, sizeof(line), "CMD|%lu|%lld|%s",
             (unsigned long)cmd_seq, (long long)now, command_payload ? command_payload : "");
    return pw_append_line(COMMANDS_FILE, 64 * 1024, 3, line);
}

esp_err_t pw_log_measurement(uint32_t meas_seq, const char *origin, double weight)
{
    int64_t now = pw_safe_epoch();
    char line[320] = {0};
    snprintf(line, sizeof(line), "MEA|%lu|%lld|%s|%.2f",
             (unsigned long)meas_seq, (long long)now, origin ? origin : "", weight);
    esp_err_t r = pw_append_line(WEIGHT_FILE, 128 * 1024, 3, line);
    if (!g_sys.sd_ok)
        ESP_LOGW(ROTULO_LOCAL, "SD down. Peso [%.2f] orig=[%s] NAO persistido em weights.txt", weight, origin ? origin : "?");
    return r;
}

esp_err_t pw_state_save_boot(esp_reset_reason_t reason, int64_t epoch)
{
    boot_reason = reason;
    boot_epoch = epoch;
    return pw_state_save();
}

esp_err_t pw_state_save(void)
{
    if (!g_sys.sd_ok)
        return ESP_OK;
    char snapshot[512] = {0};
    int offset = 0;

    offset += snprintf(snapshot + offset, sizeof(snapshot) - offset, "boot_epoch:%lld;\n", (long long)boot_epoch);
    offset += snprintf(snapshot + offset, sizeof(snapshot) - offset, "reset_reason:%d;\n", (int)boot_reason);
    offset += snprintf(snapshot + offset, sizeof(snapshot) - offset, "baby_id:%s;\n", baby_id);
    for (int i = 0; i < number_of_weight_times && offset < (int)sizeof(snapshot); i++)
        offset += snprintf(snapshot + offset, sizeof(snapshot) - offset, "weight_time:%02d:%02d;\n", weight_times[i].hour, weight_times[i].minutes);

    if (offset <= 0 || offset >= (int)sizeof(snapshot))
    {
        ESP_LOGE(ROTULO_LOCAL, "Snapshot de state excedeu buffer");
        return ESP_FAIL;
    }

    return sdcard_overwrite_file(STATE_FILE, snapshot);
}

esp_err_t pw_outbox_add(uint32_t seq, const char *topic, int qos, const char *payload)
{
    if (g_sys.sd_ok)
    {
        char line[400] = {0};
        snprintf(line, sizeof(line), "P|%lu|%d|%s|%s",
                 (unsigned long)seq, qos, topic ? topic : "", payload ? payload : "");
        return pw_append_line(OUTBOX_FILE, 256 * 1024, 2, line);
    }
    return pw_ram_buffer_enqueue(seq, topic, qos, payload);
}

esp_err_t pw_outbox_mark_sent(uint32_t seq)
{
    if (!g_sys.sd_ok)
        return ESP_OK;
    char line[64] = {0};
    snprintf(line, sizeof(line), "S|%lu", (unsigned long)seq);
    return pw_append_line(OUTBOX_FILE, 256 * 1024, 2, line);
}

esp_err_t pw_outbox_load_pending(pw_outbox_entry_t *entries, size_t max_entries, size_t *out_count)
{
    if (entries == NULL || out_count == NULL || max_entries == 0)
    {
        return ESP_ERR_INVALID_ARG;
    }
    *out_count = 0;

    if (!g_sys.sd_ok)
    {
        if (pw_ram_buffer_has_data())
        {
            if (pw_ram_buffer_dequeue(entries) == 1)
                *out_count = 1;
        }
        return ESP_OK;
    }

    struct stat st = {0};
    if (stat(OUTBOX_FILE, &st) != 0)
    {
        return ESP_OK;
    }

    FILE *file = fopen(OUTBOX_FILE, "r");
    if (file == NULL)
    {
        return ESP_FAIL;
    }

#define MAX_SENT_IDS 128
    uint32_t sent_ids[MAX_SENT_IDS];
    size_t sent_count = 0;

    char line[512];
    while (fgets(line, sizeof(line), file))
    {
        if (line[0] == 'S' && line[1] == '|')
        {
            unsigned long seq;
            if (sscanf(line, "S|%lu", &seq) == 1)
            {
                if (sent_count < MAX_SENT_IDS)
                {
                    sent_ids[sent_count++] = (uint32_t)seq;
                }
            }
        }
    }

    rewind(file);
    size_t out_idx = 0;
    while (fgets(line, sizeof(line), file) && out_idx < max_entries)
    {
        if (line[0] != 'P' || line[1] != '|')
            continue;

        unsigned long seq;
        int qos;
        char topic[PW_OUTBOX_TOPIC_MAX];
        char payload[PW_OUTBOX_PAYLOAD_MAX];

        if (sscanf(line, "P|%lu|%d|%63[^|]|%255[^\n]",
                   &seq, &qos, topic, payload) != 4)
        {
            continue;
        }

        bool is_sent = false;
        for (size_t i = 0; i < sent_count; i++)
        {
            if (sent_ids[i] == (uint32_t)seq)
            {
                is_sent = true;
                break;
            }
        }

        if (!is_sent)
        {
            entries[out_idx].seq = (uint32_t)seq;
            entries[out_idx].qos = qos;
            strncpy(entries[out_idx].topic, topic, sizeof(entries[out_idx].topic) - 1);
            entries[out_idx].topic[sizeof(entries[out_idx].topic) - 1] = '\0';
            strncpy(entries[out_idx].payload, payload, sizeof(entries[out_idx].payload) - 1);
            entries[out_idx].payload[sizeof(entries[out_idx].payload) - 1] = '\0';
            out_idx++;
        }
    }

    fclose(file);
    *out_count = out_idx;
    return ESP_OK;
}

esp_err_t pw_ram_buffer_enqueue(uint32_t seq, const char *topic, int qos, const char *payload)
{
    if (s_ram_count >= PW_RAM_BUFFER_SLOTS)
    {
        ESP_LOGE(ROTULO_LOCAL, "RAM buffer CHEIO (slot=%d). Dado descartado: seq=%lu topic=%s",
                 PW_RAM_BUFFER_SLOTS, (unsigned long)seq, topic ? topic : "?");
        return ESP_ERR_NO_MEM;
    }
    s_ram_buf[s_ram_head].seq = seq;
    s_ram_buf[s_ram_head].qos = qos;
    strncpy(s_ram_buf[s_ram_head].topic, topic ? topic : "", sizeof(s_ram_buf[s_ram_head].topic) - 1);
    s_ram_buf[s_ram_head].topic[sizeof(s_ram_buf[s_ram_head].topic) - 1] = '\0';
    strncpy(s_ram_buf[s_ram_head].payload, payload ? payload : "", sizeof(s_ram_buf[s_ram_head].payload) - 1);
    s_ram_buf[s_ram_head].payload[sizeof(s_ram_buf[s_ram_head].payload) - 1] = '\0';

    s_ram_head = (s_ram_head + 1) % PW_RAM_BUFFER_SLOTS;
    s_ram_count++;
    ESP_LOGW(ROTULO_LOCAL, "RAM buffer: enqueue seq=%lu (%d/%d)", (unsigned long)seq, (int)s_ram_count, PW_RAM_BUFFER_SLOTS);
    return ESP_OK;
}

size_t pw_ram_buffer_dequeue(pw_outbox_entry_t *out_entry)
{
    if (s_ram_count == 0 || out_entry == NULL)
        return 0;
    *out_entry = s_ram_buf[s_ram_tail];
    memset(&s_ram_buf[s_ram_tail], 0, sizeof(pw_outbox_entry_t));
    s_ram_tail = (s_ram_tail + 1) % PW_RAM_BUFFER_SLOTS;
    s_ram_count--;
    return 1;
}

bool pw_ram_buffer_has_data(void)
{
    return s_ram_count > 0;
}
