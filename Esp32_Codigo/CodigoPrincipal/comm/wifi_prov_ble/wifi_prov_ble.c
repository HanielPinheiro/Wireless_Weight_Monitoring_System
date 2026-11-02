/*
    Adaptado de: https://github.com/espressif/esp-idf/blob/release/v5.4/examples/provisioning/wifi_prov_mgr/main/app_main.c
    por Haniel Pinheiro
*/

#include "../../config/config.h"

#pragma region DATE_TIME

#define STORAGE_NAMESPACE "storage"
#define TIME_PERIOD (86400000000ULL)

static EventGroupHandle_t wifi_event_group;
static const char *ROTULO_LOCAL = "WIFI";
static bool prov_mgr_inited = false;
static uint8_t wifi_disconnect_count = 0;
static const uint8_t WIFI_DISCONNECT_MAX = 15;

#define WIFI_STA_CONNECT_TIMEOUT_MS 15000
#define WIFI_STA_RETRY_MAX 3
#define PROV_POLL_MS 500

static void initialize_sntp(void)
{
    esp_sntp_config_t config = ESP_NETIF_SNTP_DEFAULT_CONFIG_MULTIPLE(2, ESP_SNTP_SERVER_LIST("a.st1.ntp.br", "b.st1.ntp.br"));
    esp_netif_sntp_init(&config);
}

static esp_err_t obtain_time(void)
{
    int retry = 0;
    const int retry_count = 10;

    while (esp_netif_sntp_sync_wait(pdMS_TO_TICKS(2000)) != ESP_OK && ++retry < retry_count)
        ESP_LOGI("DATE_TIME", "Waiting for system time to be set... (%d/%d)", retry, retry_count);

    if (retry == retry_count)
        return ESP_FAIL;

    return ESP_OK;
}

static esp_err_t fetch_and_store_time_in_nvs(void *args)
{
    (void)args;
    ESP_LOGI("DATE_TIME", "Iniciando fetch_and_store_time_in_nvs");
    nvs_handle_t my_handle = 0;
    esp_err_t err;

    ESP_LOGI("DATE_TIME", "Inicializando SNTP");
    initialize_sntp();

    ESP_LOGI("DATE_TIME", "Obtendo tempo...");
    if (obtain_time() != ESP_OK)
    {
        ESP_LOGE("DATE_TIME", "Falha ao obter tempo do NTP");
        err = ESP_FAIL;
        goto exit;
    }

    time_t now;
    time(&now);
    ESP_LOGI("DATE_TIME", "Tempo obtido: %lld", (long long)now);

    err = nvs_open(STORAGE_NAMESPACE, NVS_READWRITE, &my_handle);
    if (err != ESP_OK)
    {
        ESP_LOGE("DATE_TIME", "Erro abrindo NVS: %s", esp_err_to_name(err));
        goto exit;
    }

    ESP_LOGI("DATE_TIME", "Armazenando timestamp no NVS");
    err = nvs_set_i64(my_handle, "timestamp", now);
    if (err != ESP_OK)
    {
        ESP_LOGE("DATE_TIME", "Erro escrevendo NVS: %s", esp_err_to_name(err));
        goto exit;
    }

    err = nvs_commit(my_handle);
    if (err != ESP_OK)
        ESP_LOGE("DATE_TIME", "Erro commit NVS: %s", esp_err_to_name(err));

exit:
    if (my_handle != 0)
        nvs_close(my_handle);

    esp_netif_sntp_deinit();

    ESP_LOGI("DATE_TIME", "fetch_and_store_time_in_nvs finalizado: %s", esp_err_to_name(err));
    return err;
}

static esp_err_t start_date_time_internal(void)
{
    if (fetch_and_store_time_in_nvs(NULL) != ESP_OK)
        return ESP_FAIL;

    const esp_timer_create_args_t nvs_update_timer_args = {
        .callback = (void *)&fetch_and_store_time_in_nvs,
    };

    esp_timer_handle_t nvs_update_timer;
    if (esp_timer_create(&nvs_update_timer_args, &nvs_update_timer) != ESP_OK)
        return ESP_FAIL;
    if (esp_timer_start_periodic(nvs_update_timer, TIME_PERIOD) != ESP_OK)
        return ESP_FAIL;

    return ESP_OK;
}

static void set_timezone_gmt3(void)
{
    setenv("TZ", "EST+3", 1);
    tzset();
}

esp_err_t start_date_time_routine(void)
{
    ESP_LOGI(ROTULO_LOCAL, "Getting Date Time from SNTP");
    vTaskDelay(pdMS_TO_TICKS(1000));
    if (start_date_time_internal() != ESP_OK)
    {
        g_sys.datetime_synced = false;
        ESP_LOGW(ROTULO_LOCAL, "Falha ao sincronizar SNTP — seguindo com tempo desde boot.");
        return ESP_OK;
    }
    set_timezone_gmt3();
    g_sys.datetime_synced = true;
    return ESP_OK;
}

#pragma endregion

static uint8_t my_bluetooth_uuid[] = {
    0xb4,
    0xdf,
    0x5a,
    0x1c,
    0x3f,
    0x6b,
    0xf4,
    0xbf,
    0xea,
    0x4a,
    0x82,
    0x03,
    0x04,
    0x90,
    0x1a,
    0x02,
};

static void event_handler(void *arg, esp_event_base_t event_base, int32_t event_id, void *event_data)
{
    (void)arg;
    if (event_base == WIFI_PROV_EVENT)
    {
        switch (event_id)
        {
        case WIFI_PROV_START:
            ESP_LOGI(ROTULO_LOCAL, "Provisioning started");
            break;
        case WIFI_PROV_CRED_RECV:
        {
            wifi_sta_config_t *wifi_sta_cfg = (wifi_sta_config_t *)event_data;
            ESP_LOGI(ROTULO_LOCAL, "Received Wi-Fi credentials\n\tSSID: %s", (const char *)wifi_sta_cfg->ssid);
            break;
        }
        case WIFI_PROV_CRED_FAIL:
        {
            wifi_prov_sta_fail_reason_t *reason = (wifi_prov_sta_fail_reason_t *)event_data;
            ESP_LOGE(ROTULO_LOCAL, "Provisioning failed!\n\tReason : %s", (*reason == WIFI_PROV_STA_AUTH_ERROR) ? "Wi-Fi station authentication failed" : "Wi-Fi access-point not found");
            break;
        }
        case WIFI_PROV_CRED_SUCCESS:
            ESP_LOGI(ROTULO_LOCAL, "Provisioning successful");
            g_sys.wifi_provisioned = true;
            break;
        case WIFI_PROV_END:
            wifi_prov_mgr_deinit();
            prov_mgr_inited = false;
            break;
        default:
            break;
        }
    }
    else if (event_base == WIFI_EVENT)
    {
        switch (event_id)
        {
        case WIFI_EVENT_STA_START:
            esp_wifi_connect();
            break;
        case WIFI_EVENT_STA_CONNECTED:
            ESP_LOGI(ROTULO_LOCAL, "Connected!");
            int rssi_strength;
            if (esp_wifi_sta_get_rssi(&rssi_strength) == ESP_OK)
                ESP_LOGI(ROTULO_LOCAL, "Wi-Fi Strength {%d}", rssi_strength);
            break;

        case WIFI_EVENT_STA_DISCONNECTED:
            ESP_LOGI(ROTULO_LOCAL, "Disconnected. Connecting to the AP again...");
            g_sys.wifi_up = false;
            g_sys.mqtt_up = false;
            g_sys.datetime_synced = false;
            esp_netif_sntp_deinit();
            wifi_disconnect_count++;
            if (wifi_disconnect_count >= WIFI_DISCONNECT_MAX)
            {
                wifi_disconnect_count = 0;
                reset_wifi();
            }
            else
            {
                esp_wifi_connect();
            }
            break;
        default:
            break;
        }
    }
    else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP)
    {
        ip_event_got_ip_t *ev = (ip_event_got_ip_t *)event_data;
        (void)ev;
        ESP_LOGI(ROTULO_LOCAL, "Connected with IP Address:" IPSTR, IP2STR(&ev->ip_info.ip));
        g_sys.wifi_up = true;
        wifi_disconnect_count = 0;
        xEventGroupSetBits(wifi_event_group, BIT0);
    }
    else if (event_base == PROTOCOMM_TRANSPORT_BLE_EVENT)
    {
        switch (event_id)
        {
        case PROTOCOMM_TRANSPORT_BLE_CONNECTED:
            ESP_LOGI(ROTULO_LOCAL, "BLE transport: Connected!");
            break;
        case PROTOCOMM_TRANSPORT_BLE_DISCONNECTED:
            ESP_LOGI(ROTULO_LOCAL, "BLE transport: Disconnected!");
            break;
        default:
            break;
        }
    }
    else if (event_base == PROTOCOMM_SECURITY_SESSION_EVENT)
    {
        switch (event_id)
        {
        case PROTOCOMM_SECURITY_SESSION_SETUP_OK:
            ESP_LOGI(ROTULO_LOCAL, "Secured session established!");
            break;
        case PROTOCOMM_SECURITY_SESSION_INVALID_SECURITY_PARAMS:
            ESP_LOGE(ROTULO_LOCAL, "Received invalid security parameters for establishing secure session!");
            break;
        case PROTOCOMM_SECURITY_SESSION_CREDENTIALS_MISMATCH:
            ESP_LOGE(ROTULO_LOCAL, "Received incorrect username and/or PoP for establishing secure session!");
            break;
        default:
            break;
        }
    }
}

static esp_err_t custom_prov_data_handler(uint32_t session_id, const uint8_t *inbuf, ssize_t inlen, uint8_t **outbuf, ssize_t *outlen, void *priv_data)
{
    (void)session_id;
    (void)priv_data;
    if (inbuf)
    {
        ESP_LOGI(ROTULO_LOCAL, "Received data: %.*s", (int)inlen, (char *)inbuf);
    }
    char response[] = "SUCCESS";
    *outbuf = (uint8_t *)strdup(response);
    if (*outbuf == NULL)
    {
        ESP_LOGE(ROTULO_LOCAL, "System out of memory");
        return ESP_ERR_NO_MEM;
    }
    *outlen = strlen(response) + 1;

    return ESP_OK;
}

static void wifi_init_all_internal(void)
{
    ESP_LOGI(ROTULO_LOCAL, "Inicializando sistema de rede e eventos...");

    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    wifi_event_group = xEventGroupCreate();

    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_PROV_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(PROTOCOMM_TRANSPORT_BLE_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(PROTOCOMM_SECURITY_SESSION_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &event_handler, NULL));

    esp_netif_create_default_wifi_sta();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));
}

static void init_prov_manager_internal(void)
{
    if (prov_mgr_inited)
        return;

    wifi_prov_mgr_config_t config = {
        .wifi_prov_conn_cfg = {.wifi_conn_attempts = 3},
        .scheme = wifi_prov_scheme_ble,
        .scheme_event_handler = WIFI_PROV_SCHEME_BLE_EVENT_HANDLER_FREE_BTDM};

    ESP_ERROR_CHECK(wifi_prov_mgr_init(config));
    prov_mgr_inited = true;
}

static void start_ble_provisioning_internal(void)
{
    ESP_LOGI(ROTULO_LOCAL, "Iniciando provisioning BLE...");
    init_prov_manager_internal();
    ESP_ERROR_CHECK(wifi_prov_scheme_ble_set_service_uuid(my_bluetooth_uuid));
    ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_create("PW_PROVISION_DATA"));
    ESP_ERROR_CHECK(wifi_prov_mgr_start_provisioning(WIFI_PROV_SECURITY_1, MQTT_POP, WIFI_DEVICE_NAME, NULL));
    ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_register("custom-data", custom_prov_data_handler, NULL));
}

static bool start_wifi_sta_internal(TickType_t timeout_ticks)
{
    ESP_LOGI(ROTULO_LOCAL, "Iniciando Wi-Fi STA com credenciais salvas...");
    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL));
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_start());
    EventBits_t bits = xEventGroupWaitBits(wifi_event_group, BIT0, pdTRUE, pdTRUE, timeout_ticks);
    if ((bits & BIT0) == 0)
    {
        ESP_LOGW(ROTULO_LOCAL, "Timeout sem obter IP (tempo=%u ms).", (unsigned)pdTICKS_TO_MS(timeout_ticks));
        return false;
    }
    wifi_disconnect_count = 0;
    return true;
}

static void wifi_manager_task(void *pvParameters)
{
    (void)pvParameters;

    wifi_init_all_internal();
    init_prov_manager_internal();

    bool provisioned = false;
    ESP_ERROR_CHECK(wifi_prov_mgr_is_provisioned(&provisioned));
    g_sys.wifi_provisioned = provisioned;

    if (provisioned)
    {
        wifi_prov_mgr_deinit();
        prov_mgr_inited = false;
        ESP_LOGI(ROTULO_LOCAL, "Dispositivo ja provisionado. Tentando conectar STA...");

        uint8_t tentativas = 0;
        bool conectou = false;
        while (tentativas < WIFI_STA_RETRY_MAX && !conectou)
        {
            g_sys.wifi_connecting = true;
            conectou = start_wifi_sta_internal(pdMS_TO_TICKS(WIFI_STA_CONNECT_TIMEOUT_MS));
            tentativas++;
            if (!conectou)
            {
                vTaskDelay(pdMS_TO_TICKS(1000));
            }
        }
        g_sys.wifi_connecting = false;

        if (!conectou)
        {
            ESP_LOGW(ROTULO_LOCAL, "Nao conseguiu IP apos %d tentativas STA. Iniciando reprovisionamento BLE...", WIFI_STA_RETRY_MAX);
            start_ble_provisioning_internal();
            while (!g_sys.wifi_up)
            {
                EventBits_t bits = xEventGroupWaitBits(wifi_event_group, BIT0, pdTRUE, pdTRUE, pdMS_TO_TICKS(PROV_POLL_MS));
                if ((bits & BIT0) != 0)
                    break;
                vTaskDelay(pdMS_TO_TICKS(10));
            }
            ESP_LOGI(ROTULO_LOCAL, "Provisionamento concluido, WiFi UP.");
        }
    }
    else
    {
        ESP_LOGW(ROTULO_LOCAL, "Dispositivo novo. Iniciando provisioning BLE...");
        start_ble_provisioning_internal();
        while (!g_sys.wifi_up)
        {
            EventBits_t bits = xEventGroupWaitBits(wifi_event_group, BIT0, pdTRUE, pdTRUE, pdMS_TO_TICKS(PROV_POLL_MS));
            if ((bits & BIT0) != 0)
                break;
            vTaskDelay(pdMS_TO_TICKS(10));
        }
        ESP_LOGI(ROTULO_LOCAL, "Provisionado e conectado.");
    }

    if (g_sys.wifi_up)
    {
        if (start_date_time_routine() == ESP_OK)
        {
            ESP_LOGI(ROTULO_LOCAL, "SNTP sincronizado. Iniciando MQTT.");
            sdcard_log(LOG_INFO, "Tasks de SD/Sensores ok. Inicializando Timers de pesagem.", ROTULO_LOCAL);
            init_weight_sensors_timer();
            update_current_time();
        }
        else
        {
            ESP_LOGW(ROTULO_LOCAL, "SNTP falhou, seguindo sem data sincronizada. Iniciando MQTT.");
        }
        init_mqtt_task();
    }

    vTaskDelete(NULL);
}

esp_err_t start_wifi_manager_async(void)
{
    TaskHandle_t h = NULL;
    BaseType_t r = xTaskCreate(wifi_manager_task, "wifi_manager", 8192, NULL, TASK_PRIORITY_MEDIUM, &h);
    if (r != pdPASS || h == NULL)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar wifi_manager_task");
        return ESP_FAIL;
    }
    return ESP_OK;
}

void reset_wifi(void)
{
    ESP_LOGI(ROTULO_LOCAL, "Performing full WiFi reset...");

    if (prov_mgr_inited)
    {
        wifi_prov_mgr_deinit();
        prov_mgr_inited = false;
    }

    ESP_ERROR_CHECK(esp_wifi_stop());
    ESP_ERROR_CHECK(esp_wifi_restore());
    ESP_ERROR_CHECK(esp_wifi_deinit());

    g_sys.wifi_up = false;
    g_sys.mqtt_up = false;
    g_sys.datetime_synced = false;

    ESP_LOGI(ROTULO_LOCAL, "Wi-Fi reseted. Restarting ESP32...");
    vTaskDelay(pdMS_TO_TICKS(1000));
    esp_restart();
}

void init_wifi(void)
{
    ESP_LOGW(ROTULO_LOCAL, "init_wifi() e OBSOLETO. Use start_wifi_manager_async() — modo assincrono.");
    start_wifi_manager_async();
}

void print_efuse_mac()
{
    uint8_t base_mac[6] = {0};
    ESP_ERROR_CHECK(esp_efuse_mac_get_default(base_mac));
    printf("Factory eFuse MAC: %02X:%02X:%02X:%02X:%02X:%02X\n", base_mac[0], base_mac[1], base_mac[2], base_mac[3], base_mac[4], base_mac[5]);
}

bool is_wifi_connected()
{
    return g_sys.wifi_up;
}

esp_err_t get_wifi_strength(int *wifi_strength)
{
    if (wifi_strength == NULL)
        return ESP_ERR_INVALID_ARG;
    return esp_wifi_sta_get_rssi(wifi_strength);
}

char current_time[SIZE_TIME];
void update_current_time()
{
    time_t now;
    struct tm timeinfo;
    time(&now);
    localtime_r(&now, &timeinfo);
    strftime(current_time, SIZE_TIME, "%d/%m/%Y %H:%M:%S", &timeinfo);
}
