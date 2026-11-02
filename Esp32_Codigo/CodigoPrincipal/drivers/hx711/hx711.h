#pragma once
#ifndef HX711_H
#define HX711_H

#define NUM_WEIGHT_SENSORS 4
#define TARE_AUTOMATICALLY "c"

#define DEFAULT_OFFSET 0

#define SCALE1_DOUT GPIO_NUM_21
#define SCALE1_SCK GPIO_NUM_22

#define SCALE2_DOUT GPIO_NUM_16
#define SCALE2_SCK GPIO_NUM_14 // PIN 17 original, 14 na atual pq deu problema na solda

#define SCALE3_DOUT GPIO_NUM_32
#define SCALE3_SCK GPIO_NUM_33

#define SCALE4_DOUT GPIO_NUM_25
#define SCALE4_SCK GPIO_NUM_26

#define HX711_INVALID_READING 0x80000000
#define AVERAGE_NUMBER 20
#define TARE_NUMBER 40
#define HX711_CHANNEL_A_128 25
#define SCALE_MEASURE_FACTOR 1000000000

#define AT_CALIBRATION 0

#include <stdint.h>
#include "driver/gpio.h"
#include "esp_err.h"

typedef struct
{
    int8_t id;
    gpio_num_t dout_pin;
    gpio_num_t sck_pin;
    int32_t offset;
    double calib_factor;
} hx711_t;

int32_t hx711_get_offset(int8_t sensor_id);
void hx711_set_offset(int8_t sensor_id, int32_t new_offset);
int64_t hx711_get_calib_factor(int8_t sensor_id);
void hx711_set_calib_factor(int8_t sensor_id, int64_t new_factor);

esp_err_t hx711_tare_safe(int8_t id);

esp_err_t hx711_initialize_sensors(void);
double hx711_read_sensor_weight(int8_t id);

#endif // HX711_H
