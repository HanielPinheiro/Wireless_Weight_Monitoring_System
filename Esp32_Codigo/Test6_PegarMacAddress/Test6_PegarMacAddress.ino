#include "esp_mac.h"

void setup() {
  Serial.begin(115200);
   uint8_t mac[8];
  esp_efuse_mac_get_default(mac);
  
  // Print the MAC address
  Serial.print("ESP32 MAC Address: ");
  for (int i = 0; i < 8; i++) Serial.print(mac[i], HEX);  
  Serial.println();
}

void loop() {
  // put your main code here, to run repeatedly:
}
