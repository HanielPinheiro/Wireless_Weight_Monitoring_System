#include "../../config/config.h"

static const char *ROTULO_LOCAL = "SENSOR_TASK";

static double s_last_readings[NUM_WEIGHT_SENSORS];
static SemaphoreHandle_t s_data_mutex[NUM_WEIGHT_SENSORS];
static SemaphoreHandle_t global_weight_mutex;
static double final_weight;

static volatile bool s_tare_in_progress = false;
void sensors_set_tare_mode(bool active)
{
    s_tare_in_progress = active;
}
#pragma region tasks functions

static void sensor_reader_task(void *arg)
{ // Leitura individual de cada sensor
    int id = (int)arg;
    TickType_t last_wake = xTaskGetTickCount();
    configASSERT(s_data_mutex[id] != NULL); // ao inves de checar se o mutex esta disponivel no loop, checa fora dele

    while (1)
    {
        if (!s_tare_in_progress)
        {
            double raw_avg = hx711_read_sensor_weight(id);
            if (raw_avg != HX711_INVALID_READING)
            {
                xSemaphoreTake(s_data_mutex[id], portMAX_DELAY);
                s_last_readings[id] = raw_avg;
                xSemaphoreGive(s_data_mutex[id]);
            }
        }
        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(100)); // Aguarda o próximo ciclo (evita polling excessivo)
    }
}

static void sensor_processor_task(void *pvParams)
{
    // Tarefa de processamento: calcula o peso global a partir dos valores mais recentes
    TickType_t last_wake = xTaskGetTickCount();
    while (1)
    {
        // Coleta todas as leituras atuais sob mutex
        double readings = 0;
        int8_t valid_count = 0;
        double sum = 0;
        for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
        {
            if (s_data_mutex[i] != NULL)
            {
                xSemaphoreTake(s_data_mutex[i], portMAX_DELAY);
                readings = s_last_readings[i];
                xSemaphoreGive(s_data_mutex[i]);
            }

            sum += readings;
            valid_count++;
        }

        if (valid_count > 0)
        {
            if (sum <= 10.0)
                sum = 0;

            set_global_weight(sum);
            ESP_LOGI(ROTULO_LOCAL, "Peso: %.2f g ", sum);
        }
        else
        {
            set_global_weight(0);
            ESP_LOGW(ROTULO_LOCAL, "Nenhum sensor gerando leitura válida");
            sdcard_log(LOG_ERROR, "Falha HX711: nenhuma leitura valida disponivel para compor o peso.", ROTULO_LOCAL);
            pw_log_event(PW_SEV_ERROR, "SENSOR_NO_VALID_READING", ROTULO_LOCAL, "Nenhum sensor gerando leitura valida");
        }

        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(1000)); // Aguarda o próximo ciclo de processamento
    }
}

#pragma endregion

double get_global_weight()
{
    if (global_weight_mutex == NULL)
    {
        ESP_LOGE("SENSORS", "Erro: Semáforo não inicializado!");
        return -1;
    }

    double w;
    xSemaphoreTake(global_weight_mutex, portMAX_DELAY);
    w = final_weight;
    xSemaphoreGive(global_weight_mutex);
    return w;
}

void set_global_weight(double new_value)
{
    xSemaphoreTake(global_weight_mutex, portMAX_DELAY);
    final_weight = new_value;
    xSemaphoreGive(global_weight_mutex);
}

esp_err_t init_sensors_task(void)
{
    // inicializa semaforo que controla acesso ao peso global
    global_weight_mutex = xSemaphoreCreateMutex();

    // Inicializa o array de leituras como inválido
    memset(s_last_readings, 0, sizeof(s_last_readings));

    // Cria uma tarefa leitora para cada sensor
    for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
    {
        s_data_mutex[i] = xSemaphoreCreateMutex();

        if (s_data_mutex[i] == NULL)
        {
            ESP_LOGE(ROTULO_LOCAL, "Falha ao criar mutex %d", i);
            return ESP_ERR_NO_MEM;
        }

        TaskHandle_t task_handle = NULL;
        if (xTaskCreate(sensor_reader_task, "sensor_reader", 4096, (void *)i, TASK_PRIORITY_HIGH, &task_handle) != pdPASS)
        {
            ESP_LOGE(ROTULO_LOCAL, "Falha ao criar tarefa para sensor %d", i);
            return ESP_ERR_NO_MEM;
        }
    }

    if (!AT_CALIBRATION)
    {
        if (xTaskCreate(sensor_processor_task, "sensor_proc", 4096, NULL, TASK_PRIORITY_MEDIUM, NULL) != pdPASS)
        {
            ESP_LOGE(ROTULO_LOCAL, "Falha ao criar tarefa de processamento");
            return ESP_ERR_NO_MEM;
        }
    }

    ESP_LOGI(ROTULO_LOCAL, "Sistema de leitura de sensores inicializado com %d tarefas leitoras", NUM_WEIGHT_SENSORS);
    return ESP_OK;
}
