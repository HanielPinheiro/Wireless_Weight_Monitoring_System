#pragma once
#ifndef SDCARD_PERSISTENCE_H
#define SDCARD_PERSISTENCE_H

typedef enum
{
    PW_SEV_INFO = 0,
    PW_SEV_WARN = 1,
    PW_SEV_ERROR = 2,
    PW_SEV_CRITICAL = 3
} pw_severity_t;

#define PW_OUTBOX_TOPIC_MAX 64
#define PW_OUTBOX_PAYLOAD_MAX 256

typedef struct
{
    uint32_t seq;
    int qos;
    char topic[PW_OUTBOX_TOPIC_MAX];
    char payload[PW_OUTBOX_PAYLOAD_MAX];
} pw_outbox_entry_t;

esp_err_t sdcard_persistence_init(void);
uint32_t pw_next_sequence_id(void);
uint32_t pw_current_sequence_id(void);
int64_t pw_safe_epoch(void);
esp_err_t pw_save_reset_reason_nvs(esp_reset_reason_t reason);

esp_err_t pw_log_event(pw_severity_t sev, const char *event_type, const char *origin, const char *msg);
esp_err_t pw_log_command(uint32_t cmd_seq, const char *command_payload);
esp_err_t pw_log_measurement(uint32_t meas_seq, const char *origin, double weight);

esp_err_t pw_state_save(void);
esp_err_t pw_state_save_boot(esp_reset_reason_t reason, int64_t boot_epoch);

esp_err_t pw_outbox_add(uint32_t seq, const char *topic, int qos, const char *payload);
esp_err_t pw_outbox_mark_sent(uint32_t seq);
esp_err_t pw_outbox_load_pending(pw_outbox_entry_t *entries, size_t max_entries, size_t *out_count);

esp_err_t pw_rotate_if_needed(const char *path, size_t max_size_bytes, uint8_t keep_versions);

#endif
