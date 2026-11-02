#include "../../config/config.h"

static char *ROTULO_LOCAL = "MQTT_TASK";
static SemaphoreHandle_t mqtt_restart_sem = NULL;
static QueueHandle_t mqtt_command_queue = NULL;
static TaskHandle_t mqtt_manager_task_handle = NULL;
static TaskHandle_t mqtt_outbox_task_handle = NULL;

#define MQTT_COMMAND_MAX_LENGTH 128

typedef struct
{
    char payload[MQTT_COMMAND_MAX_LENGTH];
} mqtt_command_entry_t;

static void mqtt_command_worker_task(void *pvParameters)
{
    mqtt_command_entry_t entry;
    while (1)
    {
        if (xQueueReceive(mqtt_command_queue, &entry, portMAX_DELAY) == pdTRUE)
            process_mqtt_data(entry.payload);
    }
}

static void mqtt_outbox_worker_task(void *pvParameters)
{
    while (1)
    {
        pw_outbox_entry_t entry; // single entry (328 B) – safe
        size_t count = 0;

        if (pw_outbox_load_pending(&entry, 1, &count) == ESP_OK && count > 0)
        {
            if (mqtt_publish(entry.topic, entry.payload, entry.qos))
            {
                pw_outbox_mark_sent(entry.seq);
            }
        }
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

void mqtt_manager_task(void *pvParameters)
{ // Wait for restart signal or periodic check
    while (1)
    {
        if (xSemaphoreTake(mqtt_restart_sem, pdMS_TO_TICKS(10000)))
        {
            ESP_LOGI(ROTULO_LOCAL, "Processing MQTT restart request");
            ESP_LOGI(ROTULO_LOCAL, "Reinitializing MQTT");
            if (mqtt_restart_client() != ESP_OK)
                ESP_LOGE(ROTULO_LOCAL, "Falha ao reiniciar cliente MQTT");
        }
    }
}

void mqtt_connection_status_callback(esp_mqtt_event_id_t connected)
{
    switch (connected)
    {
    case MQTT_EVENT_CONNECTED:
        publish_wifi_is_connected();
        break;

    case MQTT_EVENT_DISCONNECTED:
        ESP_LOGW(ROTULO_LOCAL, "MQTT - Disconnected from broker");
        pw_log_event(PW_SEV_WARN, "MQTT_DISCONNECTED", ROTULO_LOCAL, "disconnected");
        break;

    case MQTT_EVENT_ERROR:
        ESP_LOGW(ROTULO_LOCAL, "MQTT - Error, forcing full reinitialization");
        pw_log_event(PW_SEV_ERROR, "MQTT_ERROR", ROTULO_LOCAL, "error");
        xSemaphoreGive(mqtt_restart_sem); // Signal the manager task
        break;

    case MQTT_EVENT_DATA:
        /**Aqui é onde eu devo tratar o DADO RECEBIDO! e avaliar o que é pra ser feito
         * A balança tem 4 canais de comunicação:
         *  /scales/ = balança recebe comandos
         *  /status/ = balança envia on/off mqtt3.c
         *  /weights/ = balança envia peso nos horarios
         *  /wifi/ = balança envia intensidade do wifi
         */
        if (strncmp(event->topic, MQTT_TOPIC_SCALES_SUB, event->topic_len) == 0)
        {
            mqtt_command_entry_t entry = {0};
            size_t copy_len = event->data_len < (MQTT_COMMAND_MAX_LENGTH - 1) ? event->data_len : (MQTT_COMMAND_MAX_LENGTH - 1);
            memcpy(entry.payload, event->data, copy_len);
            entry.payload[copy_len] = '\0';

            update_current_time();
            sdcard_log(LOG_INFO, current_time, ROTULO_LOCAL);
            sdcard_log(LOG_INFO, "MENSAGEM RECEBIDA VIA MQTT:", ROTULO_LOCAL);
            sdcard_log(LOG_INFO, entry.payload, ROTULO_LOCAL);
            pw_log_event(PW_SEV_INFO, "MQTT_COMMAND_RX", ROTULO_LOCAL, entry.payload);

            if (xQueueSend(mqtt_command_queue, &entry, pdMS_TO_TICKS(50)) != pdTRUE)
                sdcard_log(LOG_ERROR, "Fila de comandos MQTT cheia", ROTULO_LOCAL);
        }
        break;

    default:
        break;
    }
}

esp_err_t init_mqtt_task()
{
    mqtt_restart_sem = xSemaphoreCreateBinary();
    mqtt_command_queue = xQueueCreate(10, sizeof(mqtt_command_entry_t));
    if (mqtt_restart_sem == NULL || mqtt_command_queue == NULL)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar recursos da task MQTT");
        return ESP_FAIL;
    }
    if (xTaskCreate(mqtt_manager_task, ROTULO_LOCAL, 4096, NULL, 5, &mqtt_manager_task_handle) != pdPASS)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar 'mqtt_manager_task'");
        return ESP_FAIL;
    }
    if (xTaskCreate(mqtt_command_worker_task, "mqtt_cmd_worker", 4096, NULL, TASK_PRIORITY_MEDIUM, NULL) != pdPASS)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar 'mqtt_command_worker_task'");
        return ESP_FAIL;
    }

    if (xTaskCreate(mqtt_outbox_worker_task, "mqtt_outbox_worker", 4096, NULL, TASK_PRIORITY_MEDIUM, &mqtt_outbox_task_handle) != pdPASS)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar 'mqtt_outbox_worker_task'");
        return ESP_FAIL;
    }

    mqtt_init(mqtt_connection_status_callback);
    return ESP_OK;
}
