#pragma once
#ifndef SENSORS_TASK_H
#define SENSORS_TASK_H

typedef struct
{
    int32_t raw_value;
    int32_t units;
    int32_t weight;
    uint8_t sensor_id;
} sensor_data_t;

esp_err_t init_sensors_task(void);
void set_global_weight(double new_value);
double get_global_weight(void);
void sensors_set_tare_mode(bool active);

#endif // SENSORS_TASK_H