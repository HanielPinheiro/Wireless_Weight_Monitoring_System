#include "../../config/config.h"

static const char *ROTULO_LOCAL = "SDCARD_TASK";
static uint8_t sd_failure_counter = 0;
static bool sd_failure_reported = false;
QueueHandle_t sdcard_log_queue = NULL;

static void sdcard_writer_task(void *pv_params)
{
    log_entry_t entry;

    while (1)
    {
        if (xQueueReceive(sdcard_log_queue, &entry, pdMS_TO_TICKS(100)))
        {
            esp_err_t ret = sdcard_write_file(entry.path, entry.message); // já com mutex lá dentro
            if (ret != ESP_OK)
            {
                vTaskDelay(pdMS_TO_TICKS(1000));
                sd_failure_counter++;
                if (sd_failure_counter == 5)
                {
                    ESP_LOGE(ROTULO_LOCAL, "Falhas recorrentes no SD. Mantendo retries para evitar perda silenciosa de recuperacao.");
                    if (!sd_failure_reported)
                    {
                        uint32_t seq = pw_next_sequence_id();
                        int64_t now = pw_safe_epoch();
                        int err = sdcard_last_errno();
                        char evt[PW_OUTBOX_PAYLOAD_MAX];
                        snprintf(evt, sizeof(evt), "EVT|%lu|%lld|CRITICAL|%s|errno=%d", (unsigned long)seq, (long long)now, err == ENOSPC ? "SD_FULL" : "SD_FAIL", err);
                        // mqtt_publish(MQTT_TOPIC_EVENTS, evt, 1);
                        pw_log_event(PW_SEV_CRITICAL, err == ENOSPC ? "SD_FULL" : "SD_FAIL", ROTULO_LOCAL, evt);
                        sd_failure_reported = true;
                    }
                }
            }
            else if (sd_failure_counter > 0)
            {
                sd_failure_counter = 0;
                sd_failure_reported = false;
            }
        }
    }
}

esp_err_t init_sdcard_task()
{
    sdcard_log_queue = xQueueCreate(10, sizeof(log_entry_t));
    if (!sdcard_log_queue)
    {
        sdcard_log(LOG_ERROR, "Falha ao criar fila de log", ROTULO_LOCAL);
        return ESP_FAIL;
    }

    if (xTaskCreate(sdcard_writer_task, "gravar_logs_sd", 4096, NULL, TASK_PRIORITY_MEDIUM, NULL) != pdPASS)
    {
        sdcard_log(LOG_ERROR, "Falha ao criar task de gravação de logs", ROTULO_LOCAL);
        return ESP_FAIL;
    }

    return ESP_OK;
}
