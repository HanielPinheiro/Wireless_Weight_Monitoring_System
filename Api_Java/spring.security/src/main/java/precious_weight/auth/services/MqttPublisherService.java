package precious_weight.auth.services;

import org.eclipse.paho.client.mqttv3.*;
import org.springframework.stereotype.Service;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static precious_weight.config.system.MqttConstants.MQTT_TOPIC_PUB_SCALE;

@Service
public class MqttPublisherService {
    private static final Logger logger = LoggerFactory.getLogger(MqttPublisherService.class);

    private final IMqttAsyncClient mqttClient;
    private final ExecutorService executor = Executors.newSingleThreadExecutor();

    public MqttPublisherService(IMqttAsyncClient mqttClient) {
        this.mqttClient = mqttClient;
    }

    public void sendCriticalCommand(String mac_address, String data_to_esp32) {
        String topic = MQTT_TOPIC_PUB_SCALE + mac_address;

        executor.submit(() -> {
            MqttMessage message = null;
            try {
                message = new MqttMessage(data_to_esp32.getBytes());
                message.setQos(2);

                logger.info("Sending data to scale {}: {}", mac_address, data_to_esp32);
                mqttClient.publish(topic, message).waitForCompletion();
                logger.info("Data sended!");
            } catch (MqttException e) {
                logger.error("Failed to send data to ESP32 {}", mac_address, e); // Error log
                try {
                    this.retryPublish(topic, message, 100);
                } catch (InterruptedException ex) {
                    logger.error("Critical Command Not Sent!", ex);
                }
            }
        });
    }


    private void retryPublish(String topic, MqttMessage message, int attempts) throws InterruptedException {
        try {

            logger.info("Retrying to send data to broker. Try {}: {} - {}", attempts, topic, message.toString());
            mqttClient.publish(topic, message).waitForCompletion();

        } catch (MqttException e) {
            if (attempts > 0) {

                Thread.sleep(1000);
                retryPublish(topic, message, attempts - 1);

            } else logger.error("Permanent failure after retries: {}", topic, e);
        }
    }
}
