/* Adaptado de: https://github.com/espressif/esp-idf/tree/master/examples/protocols/mqtt/ssl_mutual_auth
 * por Haniel Pinheiro - MQTT v3*/

/*
   Necessita  Conectar na internet corretamente (etapa feita pelo wifi_prov_ble)
   Ajustar o caminho ate os certificados no cmakelists
*/
// EXPLICACAO
/*  Na criptografia TLS, o cliente deve garantir que está falando com o servidor certo. Isso é feito comparando:
 *  Common Name (CN) ou Subject Alternative Name (SAN) DO certificado do servidor COM o nome do host no URI (broker.address.uri)
 *  Essa opção(.broker.verification.skip_cert_common_name_check = true) diz ao ESP32: Não se preocupe se o nome comum (CN) do certificado do servidor não bate com o hostname que estou usando no código.
 *  Se seu server.crt tem: CN = precious_weight E seu código usa: .broker.address.uri = "mqtts://192.168.0.10:8883" o ESP32 rejeita o acesso e retorna o erro: mbedtls_ssl_handshake returned -0x2700
 *  pois o esp nao comporta conexoes com CN=192.168.0.10 (CN = IP), portanto, deve-se testar usando .broker.verification.skip_cert_common_name_check = true e depois desativar em producao,
 *  visto que será impossível satisfazer o CN do certificado = CN do servidor, pois o servidor tem dominio = IP e não DHCP
 *  Em ambiente de produção, o ideal é: 1. Usar nomes de domínio válidos (FQDN); 2. Certificados com CN = nome do domínio; 3. E não usar .skip_cert_common_name_check = true para garantir segurança contra ataques man-in-the-middle (MITM) */

#include "../../config/config.h"

static const char *ROTULO_LOCAL = "MQTT";
static bool connected = false;
static mqtt_connection_callback_t connection_cb = NULL;
static esp_mqtt_client_handle_t client = NULL;
static SemaphoreHandle_t mqtt_mutex = NULL;
esp_mqtt_event_handle_t event = NULL;

extern const uint8_t client_cert_pem_start[] asm("_binary_client_crt_start");
extern const uint8_t client_cert_pem_end[] asm("_binary_client_crt_end");
extern const uint8_t client_key_pem_start[] asm("_binary_client_key_start");
extern const uint8_t client_key_pem_end[] asm("_binary_client_key_end");
extern const uint8_t ca_cert_pem_start[] asm("_binary_ca_crt_start");
extern const uint8_t ca_cert_pem_end[] asm("_binary_ca_crt_end");

static bool mqtt_lock(TickType_t timeout_ticks)
{
    return mqtt_mutex != NULL && xSemaphoreTake(mqtt_mutex, timeout_ticks) == pdTRUE;
}

static void mqtt_unlock(void)
{
    if (mqtt_mutex != NULL)
        xSemaphoreGive(mqtt_mutex);
}

static esp_err_t mqtt_destroy_client_locked(void)
{
    if (client == NULL)
    {
        connected = false;
        return ESP_OK;
    }

    esp_mqtt_client_stop(client);
    esp_mqtt_client_destroy(client);
    client = NULL;
    connected = false;
    return ESP_OK;
}

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data)
{
    esp_mqtt_event_id_t mqtt_event = (esp_mqtt_event_id_t)event_id;

    switch (mqtt_event)
    {
    case MQTT_EVENT_CONNECTED:
        connected = true;
        g_sys.mqtt_up = true;

        // AQUI SE INSCREVE NO CANAL DO MQTT PRA OUVIR EVENTOS!!!
        esp_mqtt_client_subscribe(client, MQTT_TOPIC_SCALES_SUB, 1);
        break;

    case MQTT_EVENT_DISCONNECTED:
        connected = false;
        g_sys.mqtt_up = false;
        break;

    case MQTT_EVENT_ERROR:
        connected = false;
        g_sys.mqtt_up = false;
        break;

    case MQTT_EVENT_DATA:
        event = event_data;
        ESP_LOGW(ROTULO_LOCAL, "Received data on topic: %.*s", event->topic_len, event->topic);
        ESP_LOGW(ROTULO_LOCAL, "Data: %.*s", event->data_len, event->data);
        break;

    default:
        break;
    }

    // trigger callback in config.c
    if (connection_cb)
        connection_cb(mqtt_event);
}

void mqtt_app_start(void)
{
    const esp_mqtt_client_config_t mqtt_cfg = {
        .broker = {.address.uri = MQTT_ADDRESS,
                   .verification = {.certificate = (const char *)ca_cert_pem_start, .skip_cert_common_name_check = false}},
        .credentials = {.authentication = {
                            .certificate = (const char *)client_cert_pem_start,
                            .key = (const char *)client_key_pem_start,
                        },
                        .client_id = WIFI_DEVICE_NAME},
        .session = {.keepalive = MQTT_KEEPALIVE, .disable_clean_session = true, .last_will = {.topic = MQTT_TOPIC_CONN_STATUS, .msg = MQTT_LAST_WILL_MSG, .msg_len = strlen(MQTT_LAST_WILL_MSG), .qos = 1, .retain = true}},
        .network = {.reconnect_timeout_ms = 10000, .disable_auto_reconnect = false}};

    if (!mqtt_lock(pdMS_TO_TICKS(1000)))
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao adquirir mutex para iniciar MQTT");
        return;
    }

    if (client != NULL)
    {
        ESP_LOGW(ROTULO_LOCAL, "Cliente MQTT ja inicializado");
        mqtt_unlock();
        return;
    }

    connected = false;
    client = esp_mqtt_client_init(&mqtt_cfg);
    if (client == NULL)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao inicializar cliente MQTT");
        mqtt_unlock();
        return;
    }

    esp_mqtt_client_register_event(client, ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
    esp_err_t err = esp_mqtt_client_start(client);
    if (err != ESP_OK)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao iniciar cliente MQTT: %s", esp_err_to_name(err));
        esp_mqtt_client_destroy(client);
        client = NULL;
    }

    mqtt_unlock();
}

void mqtt_init(mqtt_connection_callback_t ext_connection_cb)
{
    connection_cb = ext_connection_cb;
    if (mqtt_mutex == NULL)
        mqtt_mutex = xSemaphoreCreateMutex();
    mqtt_app_start();
}

bool mqtt_publish(const char *topic, const char *data, int qos)
{
    if (!mqtt_lock(pdMS_TO_TICKS(1000)))
    {
        ESP_LOGW(ROTULO_LOCAL, "Timeout ao tentar pegar mutex do MQTT");
        return false;
    }

    bool can_publish = client != NULL && connected;
    int msg_id = -1;
    if (!can_publish)
        ESP_LOGW(ROTULO_LOCAL, "Cannot publish - not connected");
    else
        msg_id = esp_mqtt_client_publish(client, topic, data, strlen(data), qos, 0);

    mqtt_unlock();
    return msg_id >= 0;
}

esp_err_t mqtt_stop_client(void)
{
    if (!mqtt_lock(pdMS_TO_TICKS(2000)))
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao adquirir mutex para parar MQTT");
        return ESP_ERR_TIMEOUT;
    }

    esp_err_t err = mqtt_destroy_client_locked();
    mqtt_unlock();
    return err;
}

esp_err_t mqtt_restart_client(void)
{
    if (!mqtt_lock(pdMS_TO_TICKS(2000)))
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao adquirir mutex para reiniciar MQTT");
        return ESP_ERR_TIMEOUT;
    }

    esp_err_t err = mqtt_destroy_client_locked();
    mqtt_unlock();
    if (err != ESP_OK)
        return err;

    mqtt_app_start();
    return ESP_OK;
}
