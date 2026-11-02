#include "../../config/config.h"

static const char *ROTULO_LOCAL = "HX711 DRIVER";
static portMUX_TYPE s_hx711_mux = portMUX_INITIALIZER_UNLOCKED;
static SemaphoreHandle_t s_mutex = NULL;

#pragma region static / private

static esp_err_t hx711_init_mutexes(void)
{
    s_mutex = xSemaphoreCreateMutex();
    if (s_mutex == NULL)
        return ESP_ERR_NO_MEM;
    return ESP_OK;
}

static esp_err_t hx711_setup(gpio_num_t dout_pin, gpio_num_t sck_pin)
{
    // Configure DOUT as input
    gpio_config_t dout_conf = {
        .pin_bit_mask = 1ULL << dout_pin,
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    ESP_ERROR_CHECK(gpio_config(&dout_conf));

    // Configure SCK as output
    gpio_config_t sck_conf = {
        .pin_bit_mask = 1ULL << sck_pin,
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    ESP_ERROR_CHECK(gpio_config(&sck_conf));

    gpio_set_level(sck_pin, 0); // idle low
    return ESP_OK;
}

static esp_err_t hx711_wait_ready_timeout(gpio_num_t dout_pin, uint32_t timeout_ms)
{
    TickType_t start_ticks = xTaskGetTickCount();
    TickType_t timeout_ticks = pdMS_TO_TICKS(timeout_ms);

    while (!gpio_get_level(dout_pin) == 0)
    {
        if ((xTaskGetTickCount() - start_ticks) > timeout_ticks)
            return ESP_ERR_TIMEOUT;
        vTaskDelay(pdMS_TO_TICKS(10));
    }
    return ESP_OK;
}

static int32_t hx711_read_raw(gpio_num_t dout_pin, gpio_num_t sck_pin)
{
    if (hx711_wait_ready_timeout(dout_pin, 200) != ESP_OK)
        return HX711_INVALID_READING;

    int32_t data = 0;
    portENTER_CRITICAL(&s_hx711_mux);
    for (int i = 0; i < HX711_CHANNEL_A_128; i++)
    {
        gpio_set_level(sck_pin, 1);
        esp_rom_delay_us(1);

        if (i < 24)
        {
            data = data << 1;
            if (gpio_get_level(dout_pin))
                data++;
        }
        gpio_set_level(sck_pin, 0);
        esp_rom_delay_us(1);
    }
    portEXIT_CRITICAL(&s_hx711_mux);

    // Convert from 24-bit signed to 32-bit signed
    if (data & 0x800000)
        data |= 0xFF000000;

    return data;
}

static void insertion_sort_int32(int32_t arr[], int n)
{
    for (int i = 1; i < n; i++)
    {
        int32_t key = arr[i];
        int j = i - 1;
        while (j >= 0 && arr[j] > key)
        {
            arr[j + 1] = arr[j];
            j--;
        }
        arr[j + 1] = key;
    }
}

#define MEDIAN_SAMPLES 7

static int32_t hx711_read_median_trimmed(gpio_num_t dout_pin, gpio_num_t sck_pin)
{
    int32_t samples[MEDIAN_SAMPLES];
    uint8_t valid = 0;
    uint16_t invalid_count = 0;

    while (valid < MEDIAN_SAMPLES)
    {
        int32_t reading = hx711_read_raw(dout_pin, sck_pin);
        if (reading != HX711_INVALID_READING)
        {
            samples[valid++] = reading;
        }
        else
        {
            invalid_count++;
            if (invalid_count > MEDIAN_SAMPLES * 2)
                return HX711_INVALID_READING;
        }
        vTaskDelay(pdMS_TO_TICKS(10));
    }

    insertion_sort_int32(samples, MEDIAN_SAMPLES);

    int64_t sum = 0;
    for (int i = 2; i < MEDIAN_SAMPLES - 2; i++)
    {
        sum += samples[i];
    }

    return (int32_t)(sum / 3);
}

static int32_t hx711_read_average(gpio_num_t dout_pin, gpio_num_t sck_pin, uint8_t samples)
{
    int64_t sum = 0;
    uint8_t count = 0;
    uint16_t invalid_count = 0;

    while (count < samples)
    {
        int32_t reading = hx711_read_raw(dout_pin, sck_pin);
        if (reading != HX711_INVALID_READING)
        {
            sum += reading;
            count++;
        }
        else
        {
            invalid_count++;
            if (invalid_count > samples)
                break;
        }
    }

    return (count == samples) ? (int32_t)(sum / samples) : HX711_INVALID_READING;
}

static esp_err_t hx711_tare(int8_t id, gpio_num_t dout_pin, gpio_num_t sck_pin)
{
    int8_t try = 0;
    int32_t new_offset = HX711_INVALID_READING;
    while (new_offset == HX711_INVALID_READING && try < 3)
    {
        new_offset = hx711_read_average(dout_pin, sck_pin, TARE_NUMBER);
        try++;
    }

    if (new_offset == HX711_INVALID_READING)
    {
        ESP_LOGW(ROTULO_LOCAL, "FALHA NA TARA, USANDO OFFSET 0");
        return ESP_ERR_INVALID_STATE;
    }

    hx711_set_offset(id, new_offset);
    ESP_LOGI(ROTULO_LOCAL, "TARA DA BALANÇA:SAMPLES{%d};OFFSET{%ld}", TARE_NUMBER, new_offset);
    return ESP_OK;
}

#pragma endregion

#pragma region public

int32_t hx711_get_offset(int8_t id)
{
    int32_t off;
    xSemaphoreTake(s_mutex, portMAX_DELAY);
    off = sensors[id].offset;
    xSemaphoreGive(s_mutex);
    return off;
}

void hx711_set_offset(int8_t id, int32_t new_offset)
{
    xSemaphoreTake(s_mutex, portMAX_DELAY);
    sensors[id].offset = new_offset;
    xSemaphoreGive(s_mutex);
}

esp_err_t hx711_tare_safe(int8_t id)
{

    char msg[80] = {0};
    snprintf(msg, sizeof(msg), "Tare_Safe [%d] - Inicializando tara", id);
    sdcard_log(LOG_ERROR, msg, ROTULO_LOCAL);

    gpio_num_t dout_pin;
    gpio_num_t sck_pin;
    xSemaphoreTake(s_mutex, portMAX_DELAY);
    dout_pin = sensors[id].dout_pin;
    sck_pin = sensors[id].sck_pin;
    xSemaphoreGive(s_mutex);

    snprintf(msg, sizeof(msg), "Tare_Safe [%d] - Tentando realizar leitura", id);
    sdcard_log(LOG_ERROR, msg, ROTULO_LOCAL);

    int32_t sensor_data;
    while (true)
    {
        sensor_data = hx711_read_average(dout_pin, sck_pin, 2);
        if (sensor_data == HX711_INVALID_READING)
        {
            snprintf(msg, sizeof(msg), "Tare_Safe [%d] - Leitura inválida", id);
            sdcard_log(LOG_ERROR, msg, ROTULO_LOCAL);
        }
        else
            break;
    }

    snprintf(msg, sizeof(msg), "Tare_Safe [%d] - Leitura feita: %ld", id, sensor_data);
    sdcard_log(LOG_ERROR, msg, ROTULO_LOCAL);

    hx711_set_offset(id, sensor_data);

    snprintf(msg, sizeof(msg), "Tare_Safe [%d] - Offset definido", id);
    sdcard_log(LOG_ERROR, msg, ROTULO_LOCAL);
    return ESP_OK;
}

esp_err_t hx711_initialize_sensors()
{
    hx711_init_mutexes();

    gpio_num_t dout_pin;
    gpio_num_t sck_pin;
    char msg[80] = {0};
    for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
    {
        xSemaphoreTake(s_mutex, portMAX_DELAY);
        dout_pin = sensors[i].dout_pin;
        sck_pin = sensors[i].sck_pin;
        xSemaphoreGive(s_mutex);

        if (hx711_setup(dout_pin, sck_pin) != ESP_OK)
        {
            snprintf(msg, sizeof(msg), "FALHA AO INICIALIZAR SENSOR %d, PORTAS: %d [DOUT] e %d [SCK].", i, (int8_t)dout_pin, (int8_t)sck_pin);
            sdcard_log(LOG_ERROR, msg, ROTULO_LOCAL);
            pw_log_event(PW_SEV_CRITICAL, "SENSOR_INIT_FAIL", ROTULO_LOCAL, msg);
            return ESP_FAIL;
        }
        snprintf(msg, sizeof(msg), "SENSOR %d INICIALIZADO: %d [DOUT], %d [SCK]. INICIANDO TARA.", i, (int8_t)dout_pin, (int8_t)sck_pin);
        sdcard_log(LOG_INFO, msg, ROTULO_LOCAL);
        pw_log_event(PW_SEV_INFO, "SENSOR_INIT_OK", ROTULO_LOCAL, msg);

        esp_err_t r = hx711_tare(i, dout_pin, sck_pin);
        if (r != ESP_OK)
            return r;

        snprintf(msg, sizeof(msg), "SENSOR %d TARA REALIZADA", i);
        sdcard_log(LOG_INFO, msg, ROTULO_LOCAL);
        pw_log_event(PW_SEV_INFO, "SENSOR_TARE_OK", ROTULO_LOCAL, msg);
    }
    // Aguarda dois segundos para estabilização térmica dos sensores
    vTaskDelay(pdMS_TO_TICKS(2000));

    return ESP_OK;
}

double hx711_read_sensor_weight(int8_t id)
{
    gpio_num_t dout_pin;
    gpio_num_t sck_pin;
    int32_t offset_local;
    double calib_local;
    xSemaphoreTake(s_mutex, portMAX_DELAY);
    dout_pin = sensors[id].dout_pin;
    sck_pin = sensors[id].sck_pin;
    offset_local = sensors[id].offset;
    calib_local = sensors[id].calib_factor;
    xSemaphoreGive(s_mutex);

    int32_t raw = hx711_read_median_trimmed(dout_pin, sck_pin);
    if (raw == HX711_INVALID_READING)
    {
        ESP_LOGW(ROTULO_LOCAL, "Sensor %d: leitura inválida", id);
        return (int64_t)HX711_INVALID_READING;
    }

    double diff = raw - offset_local;

    if (AT_CALIBRATION)
        ESP_LOGI(ROTULO_LOCAL, "Sensor[%d]:Raw{%ld}|Offset{%ld}|Diff{%f}", id, raw, offset_local, diff);

    return diff / calib_local;
}

#pragma endregion
