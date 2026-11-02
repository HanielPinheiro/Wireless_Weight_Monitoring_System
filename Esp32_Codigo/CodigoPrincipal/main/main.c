/* Videos uteis
 * https://www.youtube.com/watch?v=7rbZFcqTaGc -> explica tasks e semaforo mutex
 * https://www.youtube.com/watch?v=s6RPzYDAMDM -> Mqtt e Wifi control semaforo binary(00:48) / (04:14) filas pra dados sensor / (12:10) Events groups /
 * https://www.youtube.com/watch?v=JzQTPnCspNM -> Outro exemplo de semaforo
 */

#include "../config/config.h"

char *ROTULO_LOCAL = "MAIN";

hx711_t sensors[NUM_WEIGHT_SENSORS] = {
    {.id = 0, .dout_pin = SCALE1_DOUT, .sck_pin = SCALE1_SCK, .offset = 405827, .calib_factor = 397.34},
    {.id = 1, .dout_pin = SCALE2_DOUT, .sck_pin = SCALE2_SCK, .offset = 217586, .calib_factor = 405.06},
    {.id = 2, .dout_pin = SCALE3_DOUT, .sck_pin = SCALE3_SCK, .offset = 316565, .calib_factor = 390.86},
    {.id = 3, .dout_pin = SCALE4_DOUT, .sck_pin = SCALE4_SCK, .offset = 310182, .calib_factor = 398.96}};

static char *ROTULO_SAFETY = "SAFETY";

static char *get_reset_reason_string(esp_reset_reason_t reason)
{
    switch (reason)
    {
    case ESP_RST_POWERON:
        return "Razao do último reset: Power-On Reset";
    case ESP_RST_SW:
        return "Razao do último reset: Software Reset (esp_restart)";
    case ESP_RST_PANIC:
        return "Razao do último reset: Panic/Crash Reset";
    case ESP_RST_INT_WDT:
        return "Razao do último reset: Interrupt Watchdog Reset";
    case ESP_RST_TASK_WDT:
        return "Razao do ultimo reset: Task Watchdog Reset";
    case ESP_RST_WDT:
        return "Razao do ultimo reset: Other Watchdog Reset";
    case ESP_RST_DEEPSLEEP:
        return "Razao do ultimo reset: Deep Sleep Wakeup";
    case ESP_RST_BROWNOUT:
        return "Razao do ultimo reset: Brownout Reset";
    case ESP_RST_SDIO:
        return "Razao do ultimo reset: SDIO Reset";
    default:
        return "Razao do ultimo reset: Unknown Reset Reason";
    }
}

static esp_err_t initialize_nvs_flash_storage(void)
{
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND)
    {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    return ret;
}

static void pw_safety_critical_loop(const char *motivo)
{
    set_pattern_to_led_task(BLINK_LED_CRITICAL_ERROR);
    while (1)
    {
        ESP_LOGE(ROTULO_SAFETY, "SISTEMA BLOQUEADO POR SEGURANCA — %s", motivo);
        vTaskDelay(pdMS_TO_TICKS(2000));
    }
}

static void pw_sanity_check_1shot(TimerHandle_t xTimer)
{
    (void)xTimer;
    ESP_LOGW(ROTULO_SAFETY, "Sanity check (120s) — SD=[%s] MQTT=[%s]",
             g_sys.sd_ok ? "OK" : "FAIL", g_sys.mqtt_up ? "OK" : "FAIL");

    if (!g_sys.sd_ok && !g_sys.mqtt_up)
    {
        pw_safety_critical_loop("SD + MQTT INDISPONIVEIS. NENHUM MEIO DE PERSISTENCIA VALIDO APOS 120S.");
    }

    if (!g_sys.sd_ok && g_sys.mqtt_up)
    {
        uint32_t seq = pw_next_sequence_id();
        int64_t now = pw_safe_epoch();
        char msg[PW_OUTBOX_PAYLOAD_MAX];
        snprintf(msg, sizeof(msg), "EVT|%lu|%lld|CRITICAL|SD_FAIL|OPERATING_ONLINE_ONLY_NO_OFFLINE_FALLBACK",
                 (unsigned long)seq, (long long)now);
        ESP_LOGW(ROTULO_SAFETY, "%s", msg);
        (void)mqtt_publish(MQTT_TOPIC_CONN_STATUS, msg, 1);
    }
}

void PW_ERROR_CHECK(esp_err_t task)
{
    if (task != ESP_OK)
    {
        ESP_LOGE(ROTULO_LOCAL, "Erro critico");
        set_pattern_to_led_task(BLINK_LED_CRITICAL_ERROR);
        while (1)
        {
            vTaskDelay(pdMS_TO_TICKS(1000));
        }
    }
}

void app_main()
{
    g_sys.boot_tick = xTaskGetTickCount();

    PW_ERROR_CHECK(initialize_led_task());
    ESP_ERROR_CHECK(set_pattern_to_led_task(BLINK_LED_STARTING_TASKS));

    // FASE 0 — Infraestrutura essencial (falha trava)
    esp_log_at_terminal(ROTULO_LOCAL, "Salvando Causa do Reset na memoria nao volatil (NVS).");
    PW_ERROR_CHECK(initialize_nvs_flash_storage());
    PW_ERROR_CHECK(pw_save_reset_reason_nvs(esp_reset_reason()));

    // FASE 1 — SD Card (falha NAO trava — degrada)
    esp_log_at_terminal(ROTULO_LOCAL, "Inicializando Cartao SD.");
    esp_err_t sd_ret = initialize_sdcard();
    if (sd_ret == ESP_OK)
    {
        g_sys.sd_ok = true;
        sdcard_log(LOG_INFO, "Cartao SD inicializado OK", ROTULO_LOCAL);
    }
    else
    {
        g_sys.sd_ok = false;
        ESP_LOGE(ROTULO_LOCAL, "Falha no SD (errno=%d). Prosseguindo SEM persistencia local.", sdcard_last_errno());
        set_pattern_to_led_task(BLINK_LED_STARTING_TASKS);
    }

    esp_log_at_terminal(ROTULO_LOCAL, "Inicializando BD em memoria.");
    PW_ERROR_CHECK(sdcard_persistence_init());

    PW_ERROR_CHECK(sdcard_log(LOG_WARN, get_reset_reason_string(esp_reset_reason()), ROTULO_LOCAL));
    PW_ERROR_CHECK(pw_log_event(PW_SEV_INFO, "BOOT", ROTULO_LOCAL, get_reset_reason_string(esp_reset_reason())));
    PW_ERROR_CHECK(pw_state_save_boot(esp_reset_reason(), pw_safe_epoch()));

    // FASE 2 — SubSistema de Pesagem (falha trava) — ANTES do WiFi
    sdcard_log(LOG_INFO, "Inicializando leitores HX711.", ROTULO_LOCAL);
    PW_ERROR_CHECK(hx711_initialize_sensors());

    sdcard_log(LOG_INFO, "Sensores inicializados. Inicializando Tasks de SD Card e Sensores.", ROTULO_LOCAL);
    if (g_sys.sd_ok)
    {
        PW_ERROR_CHECK(init_sdcard_task());
    }
    PW_ERROR_CHECK(init_sensors_task());

    if (!AT_CALIBRATION)
    {
        // FASE 3 — WiFi / SNTP / MQTT — ASSINCRONO (não trava app_main)
        sdcard_log(LOG_INFO, "Iniciando stack WiFi em task dedicada...", ROTULO_LOCAL);
        PW_ERROR_CHECK(start_wifi_manager_async());

        // FASE 4 — Sanity check 1-shot (120s após boot)
        static TimerHandle_t sanity_timer = NULL;
        if (sanity_timer == NULL)
        {
            sanity_timer = xTimerCreate("sanity_chk", pdMS_TO_TICKS(120 * 1000), pdFALSE, NULL, pw_sanity_check_1shot);
            if (sanity_timer == NULL || xTimerStart(sanity_timer, 0) != pdPASS)
            {
                ESP_LOGE(ROTULO_LOCAL, "Falha ao criar timer sanity_check");
            }
        }
    }

    // tare_routine(TARE_AUTOMATICALLY); // Após inicialização, realiza tara

    // Sistema operante
    char m[90] = {0};
    snprintf(m, 90, "Sistema inicializado com sucesso (SD=%s). WiFi inicializando em background. \r\n", g_sys.sd_ok ? "OK" : "FAIL");
    PW_ERROR_CHECK(sdcard_log(LOG_INFO, m, ROTULO_LOCAL));
    PW_ERROR_CHECK(pw_state_save());
    PW_ERROR_CHECK(set_pattern_to_led_task(BLINK_LED_NORMAL_OPER));
}
