#pragma once
#ifndef WIFI_H
#define WIFI_H

#define SIZE_TIME 50
extern char current_time[SIZE_TIME];

esp_err_t start_date_time_routine(void);
void update_current_time(void);
void print_efuse_mac(void);

void start_ble_provisioning(void);
void reset_wifi(void);
void init_wifi(void);
esp_err_t start_wifi_manager_async(void);
bool is_wifi_connected(void);
esp_err_t get_wifi_strength(int *wifi_strength);

#endif // WIFI_H
