#include "WiFi.h"
#include "PubSubClient.h"

// Replace with your own local test values
const char* ssid = "<YOUR_WIFI_SSID>";
const char* password = "<YOUR_WIFI_PASSWORD>";
const char* mqtt_server = "<YOUR_BROKER_HOST>";
const int port = 5278;
char* globalTopic = "status";
long lastMsg;

WiFiClient espClient;
PubSubClient client(espClient);

void setup() {
  Serial.begin(115200);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());

  client.setServer(mqtt_server, port);
  client.setCallback(callback);
}

void callback(char* topic, byte* message, unsigned int length) {
  Serial.print("Message arrived on topic: ");
  Serial.println(topic);

  String messageTemp;
  for (int i = 0; i < length; i++) messageTemp += (char)message[i];
  Serial.print("Message: ");
  Serial.println(messageTemp);
}

void loop() {
  if (!client.connected()) { reconnect(); }
  client.loop();

  long now = millis();
  if (now - lastMsg > 5000) {
    lastMsg = now;
    client.publish(globalTopic, "xablau do esp32");
    delay(1000);
    client.publish(globalTopic, "Vai embrazando");
  }
}

void reconnect() {
  // Loop until we're reconnected
  while (!client.connected()) {
    Serial.println("Trying connect to MQTT");
    // Attempt to connect
    if (client.connect("MyScale")) {
      client.subscribe(globalTopic);
      Serial.println("connected");
    } else {
      Serial.print("failed, rc = ");
      Serial.println(client.state());
      delay(5000);
      Serial.println("try conn again");
    }
  }
}
