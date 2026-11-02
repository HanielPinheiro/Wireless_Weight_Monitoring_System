#pragma once
#ifndef SETUP_H
#define SETUP_H

// --- Bibliotecas Standard & Sistema ---
#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <sys/unistd.h>
#include <sys/stat.h>
#include <errno.h>

// --- FreeRTOS ---
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "freertos/semphr.h"
#include "freertos/queue.h"
#include "freertos/portmacro.h"

// --- ESP-IDF Core & Drivers ---
#include "esp_err.h"
#include "esp_log.h"
#include "esp_system.h"
#include "esp_timer.h"
#include "esp_wifi.h"
#include "esp_mac.h"
#include "esp_netif_sntp.h"
#include "esp_vfs_fat.h"
#include "nvs_flash.h"
#include "driver/gpio.h"
#include "sdmmc_cmd.h"
#include "mqtt_client.h"

// --- ESP-IDF Provisioning ---
#include "wifi_provisioning/manager.h"
#include "wifi_provisioning/scheme_ble.h"

// --- Xtensa & Low Level ---
#include "xtensa_api.h"
#include "xt_utils.h"

// --- Suas Bibliotecas (Custom Libs) ---

#include "wifi_prov_ble.h"
#include "mqtt3.h"
#include "sdcard.h"
#include "sdcard_persistence.h"
#include "hx711.h"
#include "process_mqtt_data.h"
#include "weight_timer_scheduler.h"

// --- Suas Tasks ---
#include "led_task.h"
#include "mqtt_task.h"
#include "sdcard_task.h"
#include "sensors_task.h"

// Prioridades das tasks
typedef enum
{
    TASK_PRIORITY_LOW = 1,
    TASK_PRIORITY_MEDIUM = 2,
    TASK_PRIORITY_HIGH = 3,
    TASK_PRIORITY_CRITICAL = 4
} task_priority_t;

#define WIFI_DEVICE_NAME "REPLACE"
#define MQTT_SERVICE_NAME "REPLACE"
#define MQTT_POP "REPLACE"

#define PW_RAM_BUFFER_SLOTS 10

typedef struct
{
    bool sd_ok;
    bool wifi_provisioned;
    bool wifi_connecting;
    bool wifi_up;
    bool mqtt_up;
    bool datetime_synced;
    uint8_t wifi_fail_count;
    TickType_t boot_tick;
} system_state_t;

extern system_state_t g_sys;

extern hx711_t sensors[NUM_WEIGHT_SENSORS];

esp_err_t pw_ram_buffer_enqueue(uint32_t seq, const char *topic, int qos, const char *payload);
size_t pw_ram_buffer_dequeue(pw_outbox_entry_t *out_entry);
bool pw_ram_buffer_has_data(void);

/*Esse arquivo é necessário pra evitar referencia circular nas dependencias*/

#endif // SETUP_H
