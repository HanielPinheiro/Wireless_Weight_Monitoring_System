#pragma once
#ifndef LED_TASK_H
#define LED_TASK_H

#include "esp_err.h"

#define LED_GPIO GPIO_NUM_2
#define LED_HIGH_LEVEL 1
#define LED_LOW_LEVEL 0

/**
 *  BLINK_LED_NORMAL_OPER                   	OPERAÇÃO NORMAL -> LED DESLIGADO
 *  BLINK_LED_CRITICAL_ERROR                    ERRO CRITICO -> LED LIGADO O TEMPO TODO
 *  BLINK_LED_STARTING_TASKS            	    INICIALIZANDO TASKS (PISCANDO LENTO)
 *  BLINK_LED_EVENTS        	                PISCADA 2x E DELAY -> OK
 *  BLINK_LED_EVENTS_ERROR	                    PISCADA 5x E DELAY -> ERRO
 */
typedef enum
{
    BLINK_LED_NORMAL_OPER,
    BLINK_LED_STARTING_TASKS,
    BLINK_LED_CRITICAL_ERROR,
    BLINK_LED_EVENTS,
    BLINK_LED_EVENTS_ERROR,
} led_pattern_t;

// Pattern definitions (timings in milliseconds)
typedef struct
{
    const int16_t on_time_ms;
    const int16_t off_time_ms;
    const int16_t repeat_count; // 0 = infinite
} led_time_pattern;

// Dictionary that relates the led_pattern enum with the time pattern on and off
typedef struct
{
    led_pattern_t pattern;
    const led_time_pattern *steps;
    int8_t num_steps;
} pattern_step;

esp_err_t initialize_led_task(void);
esp_err_t set_pattern_to_led_task(led_pattern_t pattern);

#endif // LED_TASK_H