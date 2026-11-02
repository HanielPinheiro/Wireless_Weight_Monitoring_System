/**
 * Exemplo extraido e adaptado de: https://github.com/espressif/esp-idf/blob/5b11d5b26a8bf151fc6bac400158859eedd413bc/examples/storage/sd_card/sdspi/main/sd_card_example_main.c
 * Por Haniel Pinheiro em 12/07/2025
 */

#include "../../config/config.h"

static const char *ROTULO_LOCAL = "SD_CARD";

struct stat st;
static sdmmc_host_t host = SDSPI_HOST_DEFAULT(); // Define que estou usando o modulo sd na configuração de conexão (pinos)   SPI
static SemaphoreHandle_t sd_mutex;               // semaphore to protect open the file that is already open by other task
static int last_sd_errno = 0;

sdmmc_card_t *sdcard = NULL;

static esp_err_t sdcard_ensure_directory_exists(const char *dir_path)
{
    struct stat dir_stat = {0};
    if (stat(dir_path, &dir_stat) == 0)
        return S_ISDIR(dir_stat.st_mode) ? ESP_OK : ESP_FAIL;

    if (mkdir(dir_path, 0775) == 0 || errno == EEXIST)
        return ESP_OK;

    last_sd_errno = errno;
    ESP_LOGE(ROTULO_LOCAL, "Falha ao criar diretorio {%s}: %s", dir_path, strerror(errno));
    return ESP_FAIL;
}

static esp_err_t sdcard_ensure_parent_directories(const char *path)
{
    char dir_path[96] = {0};
    size_t len = strlen(path);

    if (len >= sizeof(dir_path))
        return ESP_ERR_INVALID_SIZE;

    strncpy(dir_path, path, sizeof(dir_path) - 1);

    for (size_t i = 1; i < len; i++)
    {
        if (dir_path[i] != '/')
            continue;

        char saved = dir_path[i];
        dir_path[i] = '\0';
        if (strlen(dir_path) > 0 && sdcard_ensure_directory_exists(dir_path) != ESP_OK)
            return ESP_FAIL;
        dir_path[i] = saved;
    }

    return ESP_OK;
}

esp_err_t sdcard_format(void)
{
    esp_err_t ret = esp_vfs_fat_sdcard_format(MOUNT_POINT, sdcard);
    if (ret != ESP_OK)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao formatar no sistema de arquivo FAT (%s)", esp_err_to_name(ret));
        return ESP_FAIL;
    }
    ESP_LOGI(ROTULO_LOCAL, "Nenhum arquivo existente, formatação concluída");
    sdcard_create_file(LOG_FILE);
    sdcard_create_file(WEIGHT_FILE);
    sdcard_create_file(BABY_HOURS_FILE);
    return ESP_OK;
}

#pragma region Init

static esp_err_t run_sdcard(void)
{
    // Montagem remete a criação virtual (dentro do sofware) do driver de comunicação
    esp_vfs_fat_sdmmc_mount_config_t mount_config = {
        .format_if_mount_failed = false,
        .max_files = 3,                    // Número máximo de arquivos abertos simultaneamente.(Cada arquivo aberto consome ~20 bytes de RAM). RAM_consumida = max_files * sizeof(FILE) + buffers  // ~100-200 bytes no total
        .allocation_unit_size = 16 * 1024, // Tamanho do cluster (unidade de alocação) do sistema de arquivos FAT.Documentação oficial sugere múltiplos de 4096 (ex.: 4KB, 16KB, 32KB).
    };

    host.max_freq_khz = 4000; // ← Ajusta a velocidade do BUS para 4MHz

    // Ajusta pullup dos pinos:
    gpio_set_pull_mode(SDCARD_CS, GPIO_PULLUP_ONLY);   // CS
    gpio_set_pull_mode(SDCARD_MISO, GPIO_PULLUP_ONLY); // MISO (obrigatório!)

    // Configura o trafego de informação via cabos (BUS)
    spi_bus_config_t bus_cfg = {
        .mosi_io_num = SDCARD_MOSI,
        .miso_io_num = SDCARD_MISO,
        .sclk_io_num = SDCARD_CLK,
        .quadwp_io_num = -1,     // Pinos para modo Quad SPI (QSPI), não usado em SD Cards (apenas para memórias Flash/QSPI).
        .quadhd_io_num = -1,     // Pinos para modo Quad SPI (QSPI), não usado em SD Cards (apenas para memórias Flash/QSPI).
        .max_transfer_sz = 4000, // Tamanho máximo de cada transferência SPI. No codigo github está 4000
    };

    /**
    * Quando Ajustar Esses Valores Acima?
        Aumente 'allocation_unit_size' se Escrever arquivos grandes (>1MB) para melhor desempenho.
        Reduza 'max_files' se Memória RAM estiver crítica (ex.: ESP32 com <80KB livres).
        Aumente 'max_transfer_sz' se Usar SD Cards de alta velocidade (teste com 8KB ou 16KB).
    */

    ESP_LOGI(ROTULO_LOCAL, "Iniciando o driver.");
    esp_err_t ret = spi_bus_initialize(host.slot, &bus_cfg, SDSPI_DEFAULT_DMA);
    if (ret != ESP_OK)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha no SPI: %s", esp_err_to_name(ret));
        return ret;
    }

    ESP_LOGI(ROTULO_LOCAL, "Bus inicializado.");
    // This initializes the slot without card detect (CD) and write protect (WP) signals.
    // Modify slot_config.gpio_cd and slot_config.gpio_wp if your board has these signals.
    sdspi_device_config_t slot_config = SDSPI_DEVICE_CONFIG_DEFAULT();
    slot_config.gpio_cs = SDCARD_CS;
    slot_config.host_id = host.slot;

    ESP_LOGI(ROTULO_LOCAL, "Montando Sistema de Arquivos (FAT)");
    ret = esp_vfs_fat_sdspi_mount(MOUNT_POINT, &host, &slot_config, &mount_config, &sdcard);

    if (ret != ESP_OK)
    {
        if (ret == ESP_FAIL)
            ESP_LOGE(ROTULO_LOCAL, "Falha na montagem do sistema de arquivos. Se desejar formatar, use a função sdcard_format.");
        else
            ESP_LOGE(ROTULO_LOCAL, "Erro não tratado. Mensagem: {%s}.", esp_err_to_name(ret));
        return ret;
    }

    // host.max_freq_khz = 10000; // Aumento a velocidade do Bus - Opcional

    ESP_LOGI(ROTULO_LOCAL, "Sistema de arquivos montado. Driver inicializado com sucesso.");
    if (sd_mutex == NULL)
        sd_mutex = xSemaphoreCreateMutex();
    if (sd_mutex == NULL)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar mutex do SD");
        return ESP_FAIL;
    }
    if (sdcard_ensure_directory_exists(SCALES_ROOT_DIR) != ESP_OK)
        return ESP_FAIL;
    sdcard_load_weight_times();
    return ESP_OK;
}

esp_err_t initialize_sdcard()
{
    uint8_t retry_count = 0;
    const uint8_t max_retries = 3;
    esp_err_t ret = ESP_FAIL;
    
    do
    {
        esp_log_at_terminal(ROTULO_LOCAL, "Loop While");
        ret = run_sdcard();
        if (ret == ESP_OK)
        {
            ret = sdcard_log(LOG_INFO, "Testando Logs no Cartao SD ", ROTULO_LOCAL);
            if (ret == ESP_OK)
                break;

            esp_log_at_terminal(ROTULO_LOCAL, "Problema ao escrever Logs!!");
            vTaskDelay(pdMS_TO_TICKS(1000));
            retry_count++;
            continue;
        }

        esp_log_at_terminal(ROTULO_LOCAL, "Falha ao iniciar Cartao SD");
        retry_count++;
        vTaskDelay(pdMS_TO_TICKS(1000));
    } while (retry_count < max_retries);

    return ret;
}

#pragma endregion

#pragma region Files

static esp_err_t sdcard_write_locked(const char *path, const char *data, const char *mode)
{
    if (MORE_LOGS)
        ESP_LOGI(ROTULO_LOCAL, "Executando escrita no arquivo {%s}", path);

    last_sd_errno = 0;
    if (sdcard_ensure_parent_directories(path) != ESP_OK)
        return ESP_FAIL;

    if (stat(path, &st) < 0)
    {
        ESP_LOGI(ROTULO_LOCAL, "Arquivo nao encontrado. Criando arquivo {%s}", path);
        esp_err_t resultado = sdcard_create_file((char *)path);
        if (resultado != ESP_OK)
        {
            ESP_LOGE(ROTULO_LOCAL, "Falha ao criar o arquivo {%s} para escrita.", path);
            return ESP_FAIL;
        }
    }

    FILE *file = fopen(path, mode);
    if (file == NULL)
    {
        last_sd_errno = errno;
        ESP_LOGE(ROTULO_LOCAL, "Falha ao abrir o arquivo {%s} para escrita.", path);
        return ESP_FAIL;
    }

    int result = strcmp(mode, "a") == 0 ? fprintf(file, "%s\n", data) : fprintf(file, "%s", data);
    fclose(file);

    if (result < 0)
    {
        last_sd_errno = errno;
        ESP_LOGE(ROTULO_LOCAL, "Erro ao tentar escrever os dados no arquivo, no caminho {%s}.", path);
        return ESP_FAIL;
    }

    if (MORE_LOGS)
        ESP_LOGI(ROTULO_LOCAL, "Arquivo escrito com sucesso.");

    return ESP_OK;
}

esp_err_t sdcard_write_file(char *path, char *data)
{
    if (sd_mutex == NULL)
        return sdcard_write_locked(path, data, "a");

    if (xSemaphoreTake(sd_mutex, pdMS_TO_TICKS(2000)) != pdTRUE)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao obter o semáforo para escrita no arquivo.");
        return ESP_FAIL;
    }

    esp_err_t ret = sdcard_write_locked(path, data, "a");
    xSemaphoreGive(sd_mutex);
    return ret;
}

esp_err_t sdcard_overwrite_file(const char *path, const char *data)
{
    if (sd_mutex == NULL)
        return sdcard_write_locked(path, data, "w");

    if (xSemaphoreTake(sd_mutex, pdMS_TO_TICKS(2000)) != pdTRUE)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao obter o semáforo para sobrescrever arquivo.");
        return ESP_FAIL;
    }

    last_sd_errno = 0;
    // Avoid ".tmp" paths here. FAT may reject names like "state.txt.tmp"
    // depending on short/long filename support, and this path is used very early at boot.
    esp_err_t ret = sdcard_write_locked(path, data, "w");

    xSemaphoreGive(sd_mutex);
    return ret;
}

esp_err_t sdcard_create_file(char *path)
{
    if (sdcard_ensure_parent_directories(path) != ESP_OK)
        return ESP_FAIL;

    FILE *file = fopen(path, "ab+");
    if (file)
    {
        last_sd_errno = 0;
        fclose(file);
        return ESP_OK;
    }

    last_sd_errno = errno;
    char m[80];
    snprintf(m, 80, "Erro ao criar arquivo %s: %s", path, strerror(errno));
    ESP_LOGE(ROTULO_LOCAL, "%s", m);
    return ESP_FAIL;
}

void sdcard_clear_file(const char *filename)
{
    (void)sdcard_overwrite_file(filename, "");
}

#pragma endregion

#pragma region LOG

esp_err_t sdcard_log(log_type_t log_type, char *message, const char *trace)
{
    esp_log_at_terminal(trace, message);

    log_entry_t entry;
    entry.path = LOG_FILE;
    snprintf(entry.message, sizeof(entry.message), "[%s] %s",
             log_type == LOG_WARN ? "WARNS" : log_type == LOG_ERROR ? "ERROR"
                                                                    : "INFOS",
             message);

    if (sdcard_log_queue)
    {
        if (xQueueSend(sdcard_log_queue, &entry, pdMS_TO_TICKS(100)) != pdTRUE)
        { // The queue will be readed (xqueuereceive) in task.c
            ESP_LOGW(ROTULO_LOCAL, "Fila de log cheia. Log descartado.");
            return ESP_FAIL;
        }
    }
    else // task_init não executada no config.c
        sdcard_write_file(LOG_FILE, entry.message);

    return ESP_OK;
}

void esp_log_at_terminal(const char *stack_trace, char *message)
{
    ESP_LOGI(stack_trace, "%s", message);
}

int sdcard_last_errno(void)
{
    return last_sd_errno;
}

#pragma endregion

#pragma region Baby

esp_err_t sdcard_load_weight_times()
{
    char m[80];
    struct stat st;
    if (stat(BABY_HOURS_FILE, &st) < 0)
    {
        ESP_LOGI(ROTULO_LOCAL, "Arquivo de rotina ainda nao existe. Criando {%s}", BABY_HOURS_FILE);
        return sdcard_create_file(BABY_HOURS_FILE);
    }

    FILE *file = fopen(BABY_HOURS_FILE, "r");
    if (file)
    {
        while (fgets(m, sizeof(m), file))
        {
            if (strstr(m, "baby_id:") == m) // Check if line starts with baby_id:
            {
                if (sscanf(m, "baby_id:%11[^;]", baby_id) == 1)
                {
                    update_has_baby_flag(true); // sensors_task acessa essa variavel, mas nao precisa de mutex aqui, pois é lida antes das tasks serem geradas
                    ESP_LOGW(ROTULO_LOCAL, "ACHOU BABY ID {%s}", baby_id);
                }
            }
            else if (strstr(m, "weight_time:") == m) // Check if line starts with weight_time:
            {
                int hour, min;
                if (sscanf(m, "weight_time:%d:%d", &hour, &min) == 2)
                {
                    if (number_of_weight_times < MAX_WEIGHT_TIMES)
                    {
                        weight_times[number_of_weight_times].hour = hour;
                        weight_times[number_of_weight_times].minutes = min;
                        number_of_weight_times++;
                        ESP_LOGW(ROTULO_LOCAL, "ACHOU HORARIO {%d:%d}", hour, min);
                    }
                }
            }
        }
        fclose(file);
        return ESP_OK;
    }

    snprintf(m, sizeof(m), "Erro ao abrir arquivo %s: %s", BABY_HOURS_FILE, strerror(errno));
    sdcard_log(LOG_ERROR, m, ROTULO_LOCAL);
    return ESP_FAIL;
}

#pragma endregion
