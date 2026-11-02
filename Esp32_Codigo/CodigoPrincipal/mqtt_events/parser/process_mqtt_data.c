#include "../../config/config.h"

static char *ROTULO_LOCAL = "PROCESS_MQTT_DATA";
static bool has_baby = false;

char baby_id[12] = {0};
SemaphoreHandle_t has_baby_mutex = NULL;
weight_time_t weight_times[MAX_WEIGHT_TIMES];
uint8_t number_of_weight_times = 0;

#pragma region Static

static int extract_number(const char *str)
{
    char *endptr;
    int num = (int)strtol(str, &endptr, 10);

    if (num > 59)
        num = 59;
    else if (num < 0)
        num = 0;

    return num;
}

static esp_err_t clear_routine()
{ // Limpa dados atuais
    memset(baby_id, 0, sizeof(baby_id));
    memset(weight_times, 0, sizeof(weight_times));
    number_of_weight_times = 0;
    update_has_baby_flag(false);
    sdcard_clear_file(BABY_HOURS_FILE);
    pw_state_save();
    stop_schedule_timer();
    return ESP_OK;
}

static esp_err_t run_routine()
{
    char routine_snapshot[256] = {0};
    int offset = 0;
    offset += snprintf(routine_snapshot, sizeof(routine_snapshot), "baby_id:%s;\n", baby_id);
    for (int i = 0; i < number_of_weight_times && offset < sizeof(routine_snapshot); i++)
        offset += snprintf(routine_snapshot + offset, sizeof(routine_snapshot) - offset, "weight_time:%02d:%02d;\n", weight_times[i].hour, weight_times[i].minutes);

    if (offset <= 0 || offset >= sizeof(routine_snapshot))
    {
        sdcard_log(LOG_ERROR, "Falha ao montar snapshot da rotina", ROTULO_LOCAL);
        return ESP_FAIL;
    }

    ESP_LOGW(ROTULO_LOCAL, "Vai salvar no SD: %s", routine_snapshot);

    if (sdcard_overwrite_file(BABY_HOURS_FILE, routine_snapshot) != ESP_OK)
        return ESP_FAIL;
    pw_state_save();

    if (scale_has_baby() && number_of_weight_times > 0)
    {
        esp_err_t schedule_ret = schedule_next_measure();
        if (schedule_ret != ESP_OK && schedule_ret != ESP_ERR_INVALID_STATE)
            return schedule_ret;
    }

    return ESP_OK;
}

static esp_err_t baby_routine(const char *data)
{
    size_t id_len = strlen(data);
    if (id_len > 0 && id_len < sizeof(baby_id))
    {
        if (clear_routine() != ESP_OK)
            return ESP_FAIL;

        strncpy(baby_id, data, sizeof(baby_id) - 1);
        baby_id[sizeof(baby_id) - 1] = '\0'; // Garante terminação nula
        update_has_baby_flag(true);
        pw_state_save();

        ESP_LOGW(ROTULO_LOCAL, "BABY_ID: %s", baby_id);
        return ESP_OK;
    }
    return ESP_FAIL;
}

static esp_err_t weight_times_routine(const char *data)
{
    weight_time_t weight;
    if (number_of_weight_times >= MAX_WEIGHT_TIMES)
        return ESP_ERR_NO_MEM;

    // Verifica se a string tem formato HH:MM (ex: "08:00")
    if (strlen(data) >= 5 && data[2] == ':')
    {
        weight.hour = (uint8_t)extract_number(&data[0]);    // HH
        weight.minutes = (uint8_t)extract_number(&data[3]); // MM
        ESP_LOGW(ROTULO_LOCAL, "Horário: %02d:%02d", weight.hour, weight.minutes);

        weight_times[number_of_weight_times] = weight;
        ESP_LOGW(ROTULO_LOCAL, "[%d] Horário: %02d:%02d", number_of_weight_times, weight_times[number_of_weight_times].hour, weight_times[number_of_weight_times].minutes);
        number_of_weight_times++;
        pw_state_save();

        return ESP_OK;
    }
    return ESP_FAIL;
}

static esp_err_t measure_routine(const char *data)
{
    (void)data;
    double global_weight = get_global_weight();
    uint32_t seq = pw_next_sequence_id();

    pw_log_measurement(seq, "manual", global_weight);

    char legacy[50];
    snprintf(legacy, sizeof(legacy), "%s{%.2f}", MANUAL_MEASURE, global_weight);
    if (!mqtt_publish(MQTT_TOPIC_WEIGHTS_PUB, legacy, 1))
        pw_outbox_add(seq, MQTT_TOPIC_WEIGHTS_PUB, 1, legacy);
    return ESP_OK;
}

esp_err_t tare_routine(const char *data)
{
    uint32_t seq = pw_next_sequence_id();
    int64_t now = pw_safe_epoch();
    char m[PW_OUTBOX_PAYLOAD_MAX];

    if (strcmp(data, TARE_AUTOMATICALLY) != 0)
    {
        snprintf(m, sizeof(m), "EVT|%lu|%lld|INFO|TARE", (unsigned long)seq, (long long)now);
        pw_log_event(PW_SEV_INFO, "TARE", ROTULO_LOCAL, "tare");
    }
    // Before starting tare sinalize sensors_task to stop measure
    sensors_set_tare_mode(true);
    vTaskDelay(pdMS_TO_TICKS(1200));

    for (int8_t i = 0; i < NUM_WEIGHT_SENSORS; i++)
        if (hx711_tare_safe(i) != ESP_OK)
            return ESP_FAIL;

    sensors_set_tare_mode(false); // Come back measure weight
    return ESP_OK;
}

static esp_err_t wifi_strength_routine(const char *data)
{
    int wifi_strength = 0;
    uint32_t seq = pw_next_sequence_id();
    int64_t now = pw_safe_epoch();
    char m[PW_OUTBOX_PAYLOAD_MAX];
    (void)data;

    if (get_wifi_strength(&wifi_strength) != ESP_OK)
        return ESP_FAIL;

    snprintf(m, sizeof(m), "EVT|%lu|%lld|INFO|WIFI_RSSI|%d", (unsigned long)seq, (long long)now, wifi_strength);
    pw_log_event(PW_SEV_INFO, "WIFI_RSSI", ROTULO_LOCAL, "wifi_rssi");

    // if (!mqtt_publish(MQTT_TOPIC_EVENTS, m, OUTBOX_QOS))
    //     pw_outbox_add(seq, MQTT_TOPIC_EVENTS, OUTBOX_QOS, m);

    char legacy[50];
    snprintf(legacy, sizeof(legacy), "%s{%d}", RECEIVED_WIFI_STRENGTH, wifi_strength);
    mqtt_publish(MQTT_TOPIC_WIFI_PUB, legacy, 1);
    return ESP_OK;
}

void publish_wifi_is_connected()
{
    ESP_LOGI(ROTULO_LOCAL, "MQTT - Connected to MQTT broker");
    mqtt_publish(MQTT_TOPIC_CONN_STATUS, "CONNECTED", 1);
    pw_log_event(PW_SEV_INFO, "MQTT_CONNECTED", ROTULO_LOCAL, "connected");
    wifi_strength_routine("a");
}

static esp_err_t wifi_routine()
{
    sdcard_log(LOG_WARN, "Desligando MQTT", ROTULO_LOCAL);
    mqtt_stop_client();
    sdcard_log(LOG_WARN, "MQTT desligado, desligando wifi", ROTULO_LOCAL);
    reset_wifi();
    return ESP_OK;
}

static const CommandHandler handlers[] = {
    {RECEIVED_BABY, baby_routine, "Baby ID recebido", "ERRO AO LER BABY ID"},
    {RECEIVED_TIMES, weight_times_routine, "Horario recebido", "ERRO AO LER WEIGHTS"},
    {RECEIVED_CLEAR, clear_routine, "Bebe e horarios apagados", "ERRO AO LER CLEAR"},
    {RECEIVED_RUN, run_routine, "Bebe e horarios salvos", "ERRO AO LER RUN"},
    {MANUAL_MEASURE, measure_routine, "Medida realizada", "ERRO AO LER MEASURE"},
    {RECEIVED_TARE, tare_routine, "Tara Realizada", "ERRO AO REALIZAR TARA"},
    {RECEIVED_WIFI_STRENGTH, wifi_strength_routine, "Intensidade do WiFi enviada", "ERRO AO LER INTENSIDADE WIFI"},
    {RECEIVED_WIFI, wifi_routine, "Reset de WiFi realizado", "ERRO AO LER WIFI"},
};

#pragma endregion

void update_has_baby_flag(bool state)
{ // Restringe o acesso à flag para evitar concorrencia
    if (has_baby_mutex == NULL)
        has_baby = state;
    else
    {
        while (true)
        {
            if (xSemaphoreTake(has_baby_mutex, pdMS_TO_TICKS(100)) == pdTRUE)
            {
                has_baby = state;
                xSemaphoreGive(has_baby_mutex);
                break;
            }
            vTaskDelay(pdMS_TO_TICKS(300));
        }
    }
}

bool scale_has_baby()
{ // Restringe o acesso à flag para evitar concorrencia
    bool result = false;
    if (has_baby_mutex == NULL)
        result = has_baby;
    else
    {
        while (true)
        {
            if (xSemaphoreTake(has_baby_mutex, pdMS_TO_TICKS(100)) == pdTRUE)
            {
                result = has_baby;
                xSemaphoreGive(has_baby_mutex);
                break;
            }
            vTaskDelay(pdMS_TO_TICKS(300));
        }
    }
    return result;
}

void process_mqtt_data(const char *mqtt_data)
{
    if (has_baby_mutex == NULL)
        has_baby_mutex = xSemaphoreCreateMutex();

    // O array handlers ja gerencia a funcao de callback quando um determinado comando for recebido
    int handlers_size = sizeof(handlers) / sizeof(handlers[0]);
    for (int i = 0; i < handlers_size; i++)
    {
        const CommandHandler *h = &handlers[i];
        size_t len = strlen(h->prefix);
        if (strncmp(mqtt_data, h->prefix, len) == 0)
        {
            uint32_t cmd_seq = pw_next_sequence_id();
            pw_log_command(cmd_seq, mqtt_data);
            if (number_of_weight_times >= MAX_WEIGHT_TIMES && strcmp(h->prefix, RECEIVED_TIMES) == 0)
            {
                mqtt_publish(MQTT_TOPIC_WEIGHTS_PUB, "ERROR_MAX_WEIGHT_TIMES_ACHIEVED", 1);
                return;
            }

            const char *data = mqtt_data + len;
            esp_err_t result = h->handler(data);
            if (result != ESP_OK)
            {
                sdcard_log(LOG_ERROR, h->log_error, ROTULO_LOCAL);
            }
            return;
        }
    }
}
