#pragma once
#ifndef SDCARD_H
#define SDCARD_H

#include "sdmmc_cmd.h"

#define MORE_LOGS false
#define MAX_LOG_LENGTH 160

#define SDCARD_MOSI GPIO_NUM_23
#define SDCARD_MISO GPIO_NUM_19
#define SDCARD_CLK GPIO_NUM_18
#define SDCARD_CS GPIO_NUM_5

#define MOUNT_POINT "/sdcard"
#define SCALES_ROOT_DIR MOUNT_POINT "/scales"
#define LOG_FILE SCALES_ROOT_DIR "/logs.txt"
#define WEIGHT_FILE SCALES_ROOT_DIR "/weights.txt"
#define BABY_HOURS_FILE SCALES_ROOT_DIR "/baby.txt"
#define STATE_FILE SCALES_ROOT_DIR "/state.txt"
#define SEQUENCE_FILE SCALES_ROOT_DIR "/sequence.txt"
#define AUDIT_FILE SCALES_ROOT_DIR "/audit.log"
#define COMMANDS_FILE SCALES_ROOT_DIR "/commands.log"
#define CRITICAL_FILE SCALES_ROOT_DIR "/critical.log"
#define OUTBOX_FILE SCALES_ROOT_DIR "/outbox.log"

typedef struct
{
    char *path;
    char message[MAX_LOG_LENGTH];
} log_entry_t;

typedef enum
{
    LOG_INFO = 0,
    LOG_WARN = 1,
    LOG_ERROR = 2
} log_type_t;

extern sdmmc_card_t *sdcard;
esp_err_t sdcard_format(void);
esp_err_t initialize_sdcard(void);
esp_err_t sdcard_write_file(char *path, char *data);
esp_err_t sdcard_overwrite_file(const char *path, const char *data);
esp_err_t sdcard_create_file(char *path);
esp_err_t sdcard_log(log_type_t log_type, char *message, const char *trace);
void esp_log_at_terminal(const char *stack_trace, char *message);
int sdcard_last_errno(void);

esp_err_t sdcard_load_weight_times();
void sdcard_clear_file(const char *filename);

#endif // SDCARD_H
