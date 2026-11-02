#pragma once
#ifndef MQTT_TASK_H
#define MQTT_TASK_H

void mqtt_connection_status_callback(esp_mqtt_event_id_t connected);
void mqtt_manager_task(void *pvParameters);
esp_err_t init_mqtt_task();

#endif // MQTT_TASK_H