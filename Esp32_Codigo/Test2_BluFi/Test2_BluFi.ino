#include "WiFiProv.h"
#include "WiFi.h"

void SysProvEvent(arduino_event_t *sys_event) {
  switch (sys_event->event_id) {
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      {
        Serial.println("\nConnected");
        break;
      }
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      {
        Serial.println("\nDisconnected");
        break;
      }
    default: break;
  }
}

void setup() {
  Serial.begin(115200);
  WiFi.onEvent(SysProvEvent);
  Serial.println("Begin Provisioning using BLE");

  // Sample uuid that user can pass during provisioning using BLE  
  const char *pop = "REPLACE";           // Proof of possession - otherwise called a PIN - string provided by the device, entered by the user in the phone app
  const char *service_name = "REPLACE";  // Name of your device (the Espressif apps expects by default device name starting with "Prov_")
  const char *service_key = NULL;         //service key is only used if the esp32 acts like a Access Point (Router). Not used in this case
  bool reset_provisioned = true;          // When true the library will automatically delete previously provisioned data.
  WiFiProv.beginProvision(NETWORK_PROV_SCHEME_BLE, NETWORK_PROV_SCHEME_HANDLER_FREE_BLE, NETWORK_PROV_SECURITY_1, pop, service_name, service_key, NULL, reset_provisioned);
}

void loop() { /*Ignored*/}
