#pragma once
#ifndef MQTT3_H
#define MQTT3_H

#define MQTT_ADDRESS "URL_MQTT_ADDRESS"
#define MQTT_RECONNECT_DELAY_MS 5000
#define MQTT_KEEPALIVE 60

#define MQTT_LAST_WILL_MSG "DISCONNECTED"

#define MQTT_TOPIC_SCALES_SUB "/scales/" MQTT_SERVICE_NAME

#define MQTT_TOPIC_WIFI_PUB "/wifi/" MQTT_SERVICE_NAME
#define MQTT_TOPIC_WEIGHTS_PUB "/weights/" MQTT_SERVICE_NAME
#define MQTT_TOPIC_CONN_STATUS "/status/" MQTT_SERVICE_NAME

// Não utilizados ainda
// #define MQTT_TOPIC_EVENTS "/events/" MQTT_SERVICE_NAME

typedef void (*mqtt_connection_callback_t)(esp_mqtt_event_id_t connected);
extern esp_mqtt_event_handle_t event;

void mqtt_app_start(void);
void mqtt_init(mqtt_connection_callback_t ext_connection_cb);
bool mqtt_publish(const char *topic, const char *data, int qos);
esp_err_t mqtt_stop_client(void);
esp_err_t mqtt_restart_client(void);

#endif // MQTT3_H
