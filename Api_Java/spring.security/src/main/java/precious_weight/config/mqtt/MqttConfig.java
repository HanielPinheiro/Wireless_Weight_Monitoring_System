package precious_weight.config.mqtt;

import org.eclipse.paho.client.mqttv3.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static precious_weight.config.system.MqttConstants.*;

@Configuration
public class MqttConfig {
    private static final Logger logger = LoggerFactory.getLogger(MqttConfig.class);
    @Value("${mqtt.broker.url}")
    private String BrokerUrl;

    @Value("${mqtt.broker.username}")
    private String Username;

    @Value("${mqtt.broker.password}")
    private String Password;

    @Bean
    public IMqttAsyncClient mqttAsyncClient() throws MqttException {
        IMqttAsyncClient client = new MqttAsyncClient(BrokerUrl, MQTT_API_SERVICE_NAME);
        client.setCallback(new MqttCallbackExtended() {
            @Override
            public void connectionLost(Throwable throwable) {
                logger.error("Lost conn with MQTT BROKER");
                logger.error(throwable.getMessage());
            }

            @Override
            public void messageArrived(String s, MqttMessage mqttMessage) throws Exception {
                logger.info("Get message from MQTT");
                logger.info(s, mqttMessage.getId(), mqttMessage.getPayload(), mqttMessage.getQos());
            }

            @Override
            public void deliveryComplete(IMqttDeliveryToken iMqttDeliveryToken) {
                logger.info("Delivery Complete");
            }

            @Override
            public void connectComplete(boolean reconnect, String serverURI) {
                logger.info("TRYING TO CONNECT to MQTT broker...");

                try {
                    MqttMessage onlineMessage = new MqttMessage("CONNECTED".getBytes());
                    onlineMessage.setQos(2);
                    onlineMessage.setRetained(true);
                    client.publish(MQTT_TOPIC_PUB_STATUS_API, onlineMessage);
                } catch (MqttException e) {
                    logger.error("Failed to send CONNECTED status", e);
                }

                logger.info("CONNECTED");
            }
        });

        MqttConnectOptions options = new MqttConnectOptions();
        options.setUserName(Username);
        options.setPassword(Password.toCharArray());
        options.setCleanSession(false); // Persistent session (QoS 2)
        options.setAutomaticReconnect(true);
        options.setConnectionTimeout(10);
        client.connect(options).waitForCompletion();

        MqttMessage onlineMessage = new MqttMessage("ONLINE".getBytes());
        onlineMessage.setQos(2);
        onlineMessage.setRetained(true);
        client.publish(MQTT_TOPIC_PUB_STATUS_API, onlineMessage);

        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            try {
                MqttMessage message = new MqttMessage("OFFLINE".getBytes());
                message.setQos(2);
                message.setRetained(true);
                client.publish(MQTT_TOPIC_PUB_STATUS_API, message);
                client.disconnect();
            } catch (MqttException e) {
                logger.error("Failed to send offline status on shutdown", e);
            }
        }));

        return client;
    }
}