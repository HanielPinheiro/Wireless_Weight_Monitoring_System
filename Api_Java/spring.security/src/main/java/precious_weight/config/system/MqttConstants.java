package precious_weight.config.system;

public class MqttConstants {
    public static final String MQTT_API_SERVICE_NAME = "PW_API_SERVICE";

    public static final String MQTT_TOPIC_PUB_STATUS_API ="api/status";
    public static final String MQTT_TOPIC_PUB_SCALE ="/scales/"; // send data to scale

    public static final String MQTT_GENERAL_TOPIC = "#";
    public static final String MQTT_TOPIC_SUB_WIFI ="/wifi/"; // check data in wifi topic for all scales
    public static final String MQTT_TOPIC_SUB_STATUS ="/status/"; // check device connection state for all scales
    public static final String MQTT_TOPIC_SUB_WEIGHT ="/weights/"; // check data in weight topic for all babies

    public static final String DEFAULT_WEIGHT_TIME= "12:00";
    public static final String MQTT_COMMAND_RUN = "[RUN]"; // send scale to start monitoring time to weight
    public static final String MQTT_COMMAND_BABY = "[BAB]"; // inform scale a new baby id
    public static final String MQTT_COMMAND_CLEAR = "[CLE]"; // remove data from last baby from scale
    public static final String MQTT_COMMAND_WEIGHT_TIME = "[TIM]"; //send a weight time to scale
    public static final String MQTT_COMMAND_CHANGE_WIFI = "[WIF]"; // Send scale reset wifi AP
    public static final String MQTT_COMMAND_WIFI_STRENGTH = "[WFS]"; // get wifi strength from scale
    public static final String MQTT_COMMAND_MANUAL_MEASURE = "[MEA]"; // get a weight measure from scale
    public static final String MQTT_COMMAND_SCHEDULED_MEASURE = "[WEI]"; // get a scheduled weight measure from scale
    public static final String MQTT_COMMAND_TARE = "[TAR]"; // Tare scale
}
