package precious_weight.auth.services;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import org.eclipse.paho.client.mqttv3.*;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import precious_weight.app.services.ScaleService;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static precious_weight.config.system.MqttConstants.*;
import static precious_weight.config.system.MqttConstants.MQTT_COMMAND_WIFI_STRENGTH;

@Service
public class MqttSubscriberService {
    private static final Logger logger = LoggerFactory.getLogger(MqttSubscriberService.class);
    private static final int qos = 2;
    private static final Pattern WIFI_STRENGTH_PATTERN = Pattern.compile("-?\\d+");

    @Autowired
    private IMqttAsyncClient mqttClient;

    @Autowired
    private ScaleService scaleService;

    @PostConstruct
    public void startMonitoring() throws MqttException {
        SubscribeToWifiTopic();
        SubscribeToStatusTopic();
        SubscribeToWeightTopic();
    }

    private void SubscribeToWifiTopic() throws MqttException {
        String topic =  MQTT_TOPIC_SUB_WIFI + MQTT_GENERAL_TOPIC;
        logger.info("Attempting to subscribe to topic: {}",topic);
        mqttClient.subscribe(topic, qos, (messageTopic, message) -> {
            String normalizedPayload = new String(message.getPayload()).trim();
            try {
                String valuePart = "";
                String cleanedTopic = messageTopic.replace(MQTT_TOPIC_SUB_WIFI, "");

                if (normalizedPayload.startsWith(MQTT_COMMAND_WIFI_STRENGTH)) {
                    valuePart = normalizedPayload.substring(MQTT_COMMAND_WIFI_STRENGTH.length()).trim();
                    if (valuePart.isEmpty()) throw new Exception(String.format("CAN'T EXTRACT VALUE PART FROM %s", normalizedPayload));

                    Matcher matcher = WIFI_STRENGTH_PATTERN.matcher(valuePart);
                    if (!matcher.find()) throw new Exception(String.format("Invalid wifi strength payload: %s", normalizedPayload));

                    scaleService.SaveWifiStrengthFromBroker(cleanedTopic, Integer.parseInt(matcher.group()));
                    logger.info("WiFi strength saved in topic: {}", messageTopic);
                }
                else {
                    throw new Exception("COMMAND NOT IDENTIFIED!");
                }
                log(messageTopic, normalizedPayload);
            } catch (Exception e) {
                logger.error("Error when try to save wifi strength - Topic: {} | Payload: {} - Error: {}", messageTopic, normalizedPayload, e.getMessage(), e);
            }
        });
        logger.info("Subscription request sent for topic: {}", topic);
    }


    private void SubscribeToStatusTopic() throws MqttException {
        String topic =  MQTT_TOPIC_SUB_STATUS + MQTT_GENERAL_TOPIC;
        logger.info("Attempting to subscribe to topic: {}", topic);
        mqttClient.subscribe(topic, qos, (messageTopic, message) -> {
            String payload = new String(message.getPayload());
            String scaleMac = messageTopic.replace(MQTT_TOPIC_SUB_STATUS, "");

            if ("CONNECTED".equalsIgnoreCase(payload)) {
                scaleService.UpdateConnectionStatusFromBroker(scaleMac, true);
                log(messageTopic, payload);
                return;
            }

            if ("DISCONNECTED".equalsIgnoreCase(payload)) {
                scaleService.UpdateConnectionStatusFromBroker(scaleMac, false);
                log(messageTopic, payload);
                return;
            }

            logger.warn("Ignoring unsupported status payload - Topic: {} | Payload: {}", messageTopic, payload);
        });
        logger.info("Subscription request sent for topic: {}", topic);
    }

    private void SubscribeToWeightTopic() throws MqttException {
        String topic =  MQTT_TOPIC_SUB_WEIGHT + MQTT_GENERAL_TOPIC;
        logger.info("Attempting to subscribe to topic: {}", topic);
        mqttClient.subscribe(topic, qos, (messageTopic, message) -> {
            String payload = new String(message.getPayload());

            try {
                logger.info("Receive new weight in topic : {} | Weight: {}", messageTopic, payload);
                log(messageTopic, payload);

                scaleService.SaveWeightFromBroker(messageTopic.replace(MQTT_TOPIC_SUB_WEIGHT, ""), payload);
                logger.info("Weight saved in topic: {}", messageTopic);
            } catch (Exception e) {
                logger.error("Error when try to save weight - Topic: {} | Weight: {} - Error: {}", messageTopic, payload, e.getMessage(), e);
            }

        });
        logger.info("Subscription request sent for topic: {}", topic);
    }

    @Scheduled(fixedRate = 300000) // Every 5 minutes
    public void logHeartbeat() {
        logger.info("MQTT subscriber is alive");
    }

    private void log(String messageTopic, String payload) {
        logger.info("Received message - Topic: {} | Payload: {}", messageTopic, payload);
    }
}
