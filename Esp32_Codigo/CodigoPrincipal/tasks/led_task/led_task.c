#include "../../config/config.h"

static const char *ROTULO_LOCAL = "LED_TASK";
static QueueHandle_t led_queue = NULL;
static const int8_t PATTERNS_NUM = 5;

static bool initialized = false;
static bool change_pattern = false;

// OPERAÇÃO NORMAL -> LED DESLIGADO
static const led_time_pattern pattern_normal[] = {{0, 100, 1}};

// ERRO CRITICO -> LED LIGADO O TEMPO TODO
static const led_time_pattern pattern_critical_error[] = {{100, 0, 1}};

// INICIALIZANDO TASKS (PISCANDO LENTO)
static const led_time_pattern pattern_task_initializer[] = {{1000, 2000, 1000}};

// PISCADA 2x E DELAY -> OK
static const led_time_pattern pattern_events[] = {{100, 100, 1}, {100, 300, 1}};

// PISCADA 5x E DELAY -> ERRO
static const led_time_pattern pattern_events_error[] = {{100, 100, 4}, {100, 300, 1}};

static const pattern_step pattern_db[] = {
    {BLINK_LED_NORMAL_OPER, pattern_normal, 1},
    {BLINK_LED_STARTING_TASKS, pattern_task_initializer, 1},
    {BLINK_LED_CRITICAL_ERROR, pattern_critical_error, 1},
    {BLINK_LED_EVENTS, pattern_events, 2},
    {BLINK_LED_EVENTS_ERROR, pattern_events_error, 2},
};

static void led_task(void *arg)
{
    led_pattern_t new_pattern;
    int8_t idx = 0;
    while (1)
    {
        if (xQueueReceive(led_queue, &new_pattern, pdMS_TO_TICKS(100)) == pdTRUE)
        {

            for (int8_t i = 0; i < PATTERNS_NUM; i++)
            {
                if (pattern_db[i].pattern == new_pattern)
                {
                    idx = i;
                    break;
                }
            }

            // ESP_LOGI(ROTULO_LOCAL, "Id do pattern [%d]", idx);
            // ESP_LOGI(ROTULO_LOCAL, "Num Steps do pattern [%d]", pattern_db[idx].num_steps);
            for (int8_t k = 0; k < pattern_db[idx].num_steps; k++)
            {
                led_time_pattern led_pattern = pattern_db[idx].steps[k];
                // ESP_LOGI(ROTULO_LOCAL, "led_pattern time on [%d]", led_pattern.on_time_ms);
                // ESP_LOGI(ROTULO_LOCAL, "led_pattern time off [%d]", led_pattern.off_time_ms);
                // ESP_LOGI(ROTULO_LOCAL, "led_pattern time repeat [%d]", led_pattern.repeat_count);
                for (int8_t j = 0; j < led_pattern.repeat_count; j++)
                {
                    if (led_pattern.on_time_ms > 0)
                    {
                        gpio_set_level(LED_GPIO, LED_HIGH_LEVEL);
                        // ESP_LOGI(ROTULO_LOCAL, "LED ON");
                        vTaskDelay(pdMS_TO_TICKS(led_pattern.on_time_ms));
                    }

                    if (led_pattern.off_time_ms > 0)
                    {
                        gpio_set_level(LED_GPIO, LED_LOW_LEVEL);
                        // ESP_LOGI(ROTULO_LOCAL, "LED OFF");
                        vTaskDelay(pdMS_TO_TICKS(led_pattern.off_time_ms));
                    }
                    if (change_pattern)
                        break;
                }
                if (change_pattern)
                    break;
            }
            if (change_pattern)
                change_pattern = false;
        }
    }
}

esp_err_t initialize_led_task(void)
{
    gpio_set_direction(LED_GPIO, GPIO_MODE_OUTPUT);
    gpio_set_level(LED_GPIO, LED_LOW_LEVEL); // start with off

    led_queue = xQueueCreate(5, sizeof(led_pattern_t));
    if (!led_queue)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar fila de LEDS");
        return ESP_FAIL;
    }

    if (xTaskCreate(led_task, "led_task", 2048, NULL, 5, NULL) != pdPASS)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar task de LEDS");
        return ESP_FAIL;
    }

    return ESP_OK;
}

esp_err_t set_pattern_to_led_task(led_pattern_t pattern)
{
    ESP_LOGI(ROTULO_LOCAL, "Pattern recebido [%d]", pattern);

    if (!led_queue)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar fila de LEDS");
        return ESP_ERR_INVALID_STATE;
    }

    if (initialized)
        change_pattern = true;
    if (!initialized)
        initialized = true;

    if (xQueueSend(led_queue, &pattern, 0) != pdTRUE)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao enviar pattern [%d] para a fila de LEDS", pattern);
        return ESP_ERR_TIMEOUT;
    }

    return ESP_OK;
}