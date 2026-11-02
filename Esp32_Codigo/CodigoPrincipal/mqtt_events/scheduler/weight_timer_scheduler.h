#pragma once
#ifndef WEIGHT_SCHEDULER_H
#define WEIGHT_SCHEDULER_H

esp_err_t init_weight_sensors_timer();
esp_err_t stop_schedule_timer();
esp_err_t schedule_next_measure();

#endif // WEIGHT_SCHEDULER_H