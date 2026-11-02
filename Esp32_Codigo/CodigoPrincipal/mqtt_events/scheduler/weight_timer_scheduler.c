#include "../../config/config.h"

static const char *ROTULO_LOCAL = "TIME_SCHEDULER";
static TimerHandle_t schedule_weight_measure_timer = NULL;
static TaskHandle_t task_worker_handle = NULL;
static bool control = false;

#pragma region Static

// Callback do timer – APENAS notifica a task_worker
static void scheduled_weight_measurement(TimerHandle_t xTimer)
{
    if (task_worker_handle != NULL)
    {
        xTaskNotifyGive(task_worker_handle);
    }
}

// Tarefa dedicada para trabalho pesado
static void task_worker(void *pvParams)
{
    (void)pvParams;
    while (1)
    {
        ulTaskNotifyTake(pdTRUE, portMAX_DELAY);

        double w = get_global_weight();
        uint32_t seq = pw_next_sequence_id();

        pw_log_measurement(seq, "scheduled", w);

        char legacy[64];
        snprintf(legacy, sizeof(legacy), "%s{%.2f}", SCHEDULED_MEASURE, w);
        if (!mqtt_publish(MQTT_TOPIC_WEIGHTS_PUB, legacy, 2))
            pw_outbox_add(seq, MQTT_TOPIC_WEIGHTS_PUB, 2, legacy);

        if (scale_has_baby() && number_of_weight_times > 0)
        {
            schedule_next_measure();
        }
    }
}

#pragma endregion

esp_err_t schedule_next_measure()
{
    if (schedule_weight_measure_timer == NULL)
    {
        ESP_LOGW(ROTULO_LOCAL, "Timer de agendamento ainda nao foi criado");
        return ESP_ERR_INVALID_STATE;
    }

    if (!scale_has_baby() || number_of_weight_times <= 0)
    {
        ESP_LOGW(ROTULO_LOCAL, "No schedule available - waiting...");
        return ESP_OK;
    }

    time_t now = 0;
    struct tm timeinfo = {0};
    time(&now);
    localtime_r(&now, &timeinfo);

    uint32_t smallest_delay = UINT32_MAX;
    int closest_idx = 0;

    for (int i = 0; i < number_of_weight_times; i++)
    {
        ESP_LOGW(ROTULO_LOCAL, "Comparing: TimeNow{%d:%d}, WeightTime[%d]{%d:%d}",
                 timeinfo.tm_hour, timeinfo.tm_min, i,
                 weight_times[i].hour, weight_times[i].minutes);

        uint32_t current_mins = timeinfo.tm_hour * 60 + timeinfo.tm_min;
        uint32_t scheduled_mins = weight_times[i].hour * 60 + weight_times[i].minutes;
        if (scheduled_mins <= current_mins)
            scheduled_mins += 1440;

        uint32_t delay_mins = scheduled_mins - current_mins;
        if (delay_mins < smallest_delay)
        {
            smallest_delay = delay_mins;
            closest_idx = i;
        }
    }

    uint32_t delay_ms = smallest_delay * 60000UL;
    if (delay_ms == 0)
    {
        if (control)
            delay_ms = 60000UL;
        else
        {
            control = true;
            delay_ms = 1000UL;
        }
    }

    ESP_LOGW(ROTULO_LOCAL, "Chosen time:{%d:%d}",
             weight_times[closest_idx].hour, weight_times[closest_idx].minutes);
    ESP_LOGW(ROTULO_LOCAL, "Delay: %lu ms (%.1f hours)", delay_ms, delay_ms / 3600000.0);

    if (xTimerChangePeriod(schedule_weight_measure_timer, pdMS_TO_TICKS(delay_ms), portMAX_DELAY) == pdPASS)
    {
        if (xTimerStart(schedule_weight_measure_timer, portMAX_DELAY) != pdPASS)
            return ESP_FAIL;
        return ESP_OK;
    }
    else
        return ESP_FAIL;
}

esp_err_t stop_schedule_timer()
{
    if (schedule_weight_measure_timer == NULL)
    {
        ESP_LOGW(ROTULO_LOCAL, "Timer not created yet, cannot stop");
        return ESP_ERR_INVALID_STATE;
    }
    if (xTimerStop(schedule_weight_measure_timer, portMAX_DELAY) != pdPASS)
    {
        ESP_LOGE(ROTULO_LOCAL, "Failed to stop timer");
        return ESP_FAIL;
    }

    ESP_LOGI(ROTULO_LOCAL, "weight_sensors_timer stopped");
    return ESP_OK;
}

esp_err_t init_weight_sensors_timer()
{
    schedule_weight_measure_timer = xTimerCreate(
        "SchedulerTimer",
        pdMS_TO_TICKS(1000),
        pdFALSE,
        (void *)0,
        scheduled_weight_measurement);
    if (schedule_weight_measure_timer == NULL)
        return ESP_FAIL;

    // Cria a tarefa dedicada (não precisa mais da queue weight_measure)
    if (xTaskCreate(task_worker, "WeightMeasure", 4096, NULL, 2, &task_worker_handle) != pdPASS)
        return ESP_FAIL;

    if (scale_has_baby() && number_of_weight_times > 0)
        return schedule_next_measure();

    return ESP_OK;
}
