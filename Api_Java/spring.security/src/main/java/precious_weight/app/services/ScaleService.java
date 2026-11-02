package precious_weight.app.services;

import precious_weight.app.interfaces.*;
import precious_weight.app.models.*;
import precious_weight.app.models.request.ScaleRequest;
import precious_weight.app.models.request.WeightRequest;
import precious_weight.auth.services.MqttPublisherService;
import precious_weight.auth.services.ScaleDataService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.concurrent.ConcurrentHashMap;

import static precious_weight.config.system.MqttConstants.*;

@Service
public class ScaleService {
    private final Map<String, Boolean> brokerConnectionStatus = new ConcurrentHashMap<>();

    public enum ScaleStates {
        nonOperant(0), operant(1);
        public final int value;

        ScaleStates(int _value) {
            value = _value;
        }
    }

    @Autowired
    private iScale iScale;

    @Autowired
    private iBaby iBaby;

    @Autowired
    private iWeight iWeight;

    @Autowired
    private iWifiStrength iWifiStrength;

    @Autowired
    private iWifiConnectivity iWifiConnectivity;

    @Autowired
    private MqttPublisherService mqttPublisherService;

    @Autowired
    private ScaleDataService scaleDataService;

    private int _globalFlagWeightNow = 0;
    private int _globalFlagWifiStrengthNow = 0;
    private double _lastManualMeasuredWeigth = 0.0;


    public int GetFlagWeightNow() {
        return _globalFlagWeightNow;
    }

    public void SetFlagWeightNow(Integer v) {
        _globalFlagWeightNow = v;
    }

    public int GetFlagWifiStrengthNow() {
        return _globalFlagWifiStrengthNow;
    }

    public void SetFlagWifiStrengthNow(Integer v) {
        _globalFlagWifiStrengthNow = v;
    }

    private void SetScaleIsConnectedIfNot(ScaleModel commercialScale){
        if(!commercialScale.getIsConnected()) commercialScale.setIsConnected(true);
        iScale.save(commercialScale);
    }

    private ScaleModel SyncLatestWifiStrength(ScaleModel scale) {
        if (scale == null || scale.getScaleId() == null) return scale;

        var latestWifiStrength = iWifiStrength.findFirstByScaleIdOrderByWifiStrengthDateDesc(scale.getScaleId())
                .map(WifiStrengthModel::getWifiStrengthValue)
                .orElse(scale.getWifiStrength());

        if (!Objects.equals(scale.getWifiStrength(), latestWifiStrength)) {
            scale.setWifiStrength(latestWifiStrength);
            iScale.save(scale);
        }

        return scale;
    }


    /**
     * *****************************************************************************************
     * CRUD FUNCTIONS
     * ******************************************************************************************
     */
    public List<ScaleModel> GetScales() {
        return iScale.findAll().stream().map(this::SyncLatestWifiStrength).toList();
    }

    public ScaleModel GetScaleFromId(Integer scaleId) {
        return iScale.findById(scaleId).map(this::SyncLatestWifiStrength).orElse(null);
    }

    public ScaleModel GetScaleFromHash(String scaleHash) {
        return iScale.findByScaleHash(scaleHash).map(this::SyncLatestWifiStrength).orElse(null);
    }

    public List<ScaleModel> GetScalesWithBaby() {
        return iScale.findAll().stream().filter(p -> p.getAssignedBaby() != null).toList();
    }

    public Integer GetBabyIdByScaleId(Integer scaleId) {
        return iScale.findById(scaleId).get().getAssignedBaby().getBabyId();

    }

    public String GetMacFromScaleByHash(String scaleHash) throws Exception {
        return scaleDataService.GetScaleMacFromScaleHashId(scaleHash);
    }

    public String GetMacFromScaleId(Integer scaleId) throws Exception {
        ScaleModel scale = GetScaleFromId(scaleId);
        if (scale == null) throw new Exception("Scale not found");
        return GetMacFromScaleByHash(scale.getScaleHash());
    }

    public ScaleModel EnableOrDisable(Integer id, boolean enabled) throws Exception {
        ScaleModel scale = GetScaleFromId(id);
        if (scale == null) throw new Exception("Scale not found");
        if (scale.getAssignedBaby() != null) throw new Exception("Scale has a baby attached to it. Unset the baby first.");

        int value = enabled ? ScaleStates.operant.value : ScaleStates.nonOperant.value;
        scale.setScaleState(value);
        iScale.save(scale);
        return GetScaleFromId(id);
    }

    public ScaleModel SetScaleToUser(UUID id) throws Exception {
        var scaleData = scaleDataService.GetScaleFromId(id);
        if (scaleData == null) throw new Exception("Invalid ID!");
        if (GetScaleFromHash(id.toString()) != null) throw new Exception("Scale already inserted");

        ScaleModel newScale = new ScaleModel();
        newScale.setScaleHash(id.toString());
        newScale.setScaleState(0);
        newScale.setIsConnected(Boolean.TRUE.equals(brokerConnectionStatus.get(scaleData.getMac())));
        newScale.setWifiStrength(0);
        return iScale.save(newScale);
    }


    public ScaleModel SetOrUnsetBabyToScale(ScaleRequest scaleRequest, boolean set) throws Exception {
        Integer scaleId = scaleRequest.getScaleId();
        Integer babyId = scaleRequest.getBabyId();

        ScaleModel scale = GetScaleFromId(scaleId);
        if (scale == null) throw new Exception("Scale not found");
        if (set) {
            if (scale.getAssignedBaby() != null) throw new Exception("Scale already has a baby");

            BabyModel baby = iBaby.findById(babyId).orElse(null);
            if (baby == null) throw new Exception("Baby not found!");

            if (BabyHasScale(babyId) != null) throw new Exception("Baby already has a scale");

            if (scale.getScaleState() == ScaleStates.nonOperant.value) throw new Exception("Scale is not operant");
            scale.setAssignedBaby(baby);
            iScale.save(scale);

            String mac = GetMacFromScaleByHash(scale.getScaleHash());
            String babyWeightTime = baby.getBabyWeightTime();
            SendBabyDataToScaleViaMqtt(mac, babyId, babyWeightTime);

            return iScale.findById(scaleId).get();
        } else {
            ScaleModel scaleWithBabyData = GetScaleFromId(scale.getScaleId());
            scaleWithBabyData.setAssignedBaby(null);

            SendClearToScaleViaMqtt(GetMacFromScaleByHash(scaleWithBabyData.getScaleHash()));

            iScale.save(scaleWithBabyData);
            return iScale.findById(scaleId).get();
        }
    }

    private Boolean BabyHasScale(Integer babyId) {
        List<ScaleModel> scales = GetScalesWithBaby(); // Get all babies for scales that have babyId assigned
        if (scales.isEmpty()) return null;
        ScaleModel find = scales.stream().filter(s -> Objects.equals(s.getAssignedBaby().getBabyId(), babyId)).toList().getFirst();
        return find != null;
    }
    /**
     ******************************************************************************************
     * End of CRUD FUNCTIONS
     * ******************************************************************************************
     */

    ///////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * *****************************************************************************************
     * Call backs from mqtt broker
     * ******************************************************************************************
     */
    public void UpdateConnectionStatusFromBroker(String scaleMac, boolean connected) {
        brokerConnectionStatus.put(scaleMac, connected);

        var authScale = scaleDataService.GetScaleFromMac(scaleMac);
        if (authScale == null) return;

        var commercialScale = GetScaleFromHash(authScale.getScaleId().toString());
        if (commercialScale == null) return;

        var wifiConnectivity = new WifiConnectivityModel(commercialScale.getScaleId(), connected);
        iWifiConnectivity.save(wifiConnectivity);

        commercialScale.setIsConnected(connected);
        if (connected) commercialScale.setLastConnectedAt(LocalDateTime.now());
        else commercialScale.setLastDisconnectedAt(LocalDateTime.now());
        iScale.save(commercialScale);
    }

    public void SaveWeightFromBroker(String scaleMac, String weight) throws Exception {
        var authScale = scaleDataService.GetScaleFromMac(scaleMac);
        if (authScale == null) throw new Exception(String.format("Can't find scale by mac %s", scaleMac));

        //Lado do cliente (id numerico, sem hash / mac
        var commercialScale = GetScaleFromHash(authScale.getScaleId().toString());
        Integer scaleId = commercialScale.getScaleId();
        Integer babyId = -1;
        try {
            babyId = this.GetBabyIdByScaleId(scaleId);
        } catch (Exception e) {
            //do nothing
        }
        SetScaleIsConnectedIfNot(commercialScale);

        var message = weight.split("\\{");//[MEA]{0.0} ou [WEI]0.0 => WEI salva no BD, MEA não
        var prefix = message[0];
        var weigth = Double.parseDouble(message[1].replace("}", ""));
        if(prefix.startsWith(MQTT_COMMAND_SCHEDULED_MEASURE)) {
            var w = new WeightRequest();
            w.setBabyId(babyId);
            w.setScaleId(scaleId);
            w.setWeightValue(weigth);
            iWeight.save(w.ToModel());
        }
        else _lastManualMeasuredWeigth = weigth;

        this.SetFlagWeightNow(1);
    }

    public void SaveWifiStrengthFromBroker(String scaleMac, Integer wifiStrengthValue) throws Exception {
        var authScale = scaleDataService.GetScaleFromMac(scaleMac);
        if (authScale == null) throw new Exception(String.format("Can't find scale by mac %s", scaleMac));

        var commercialScale = GetScaleFromHash(authScale.getScaleId().toString());
        if (commercialScale == null) throw new Exception(String.format("Can't find scale by hash %s", authScale.getScaleId()));

        WifiStrengthModel wifiStrengthModel = new WifiStrengthModel();
        wifiStrengthModel.setScaleId(commercialScale.getScaleId());
        wifiStrengthModel.setWifiStrengthDate(LocalDateTime.now());
        wifiStrengthModel.setWifiStrengthValue(wifiStrengthValue);

        iWifiStrength.save(wifiStrengthModel);
        commercialScale.setWifiStrength(wifiStrengthValue);
        SetScaleIsConnectedIfNot(commercialScale);

        this.SetFlagWifiStrengthNow(1);
    }

    /**
     ******************************************************************************************
     * END OF Call backs from mqtt
     * ******************************************************************************************
     */

    ///////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * *****************************************************************************************
     * Send data to MQTT
     * ******************************************************************************************
     */
    public void SendNewWeightTimesToScaleViaMqtt(Integer babyId, String babyWeightTime) throws Exception {
        String hash = iBaby.getReferenceById(babyId).getAssignedScale().getScaleHash();
        String mac = GetMacFromScaleByHash(hash);
        SendClearToScaleViaMqtt(mac);
        SendBabyDataToScaleViaMqtt(mac, babyId, babyWeightTime);
    }

    private void SendClearToScaleViaMqtt(String mac) {
        mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_CLEAR);
    }

    private void SendBabyDataToScaleViaMqtt(String mac, Integer babyId, String babyWeightTime) throws Exception {
        //Envio [BAB]ID
        mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_BABY + babyId.toString());

        //Envio [TIM]time
        if (babyWeightTime == null)  //time = 12:00
            mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_WEIGHT_TIME + DEFAULT_WEIGHT_TIME);

        else { // vários 'times' =>08:00$09:00$10:00...
            String[] weightTimes = babyWeightTime.split("\\$");
            if (weightTimes.length == 0)
                mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_WEIGHT_TIME + babyWeightTime);
            else
                for (String weightTime : weightTimes) mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_WEIGHT_TIME + weightTime);
        }

        //Envio [RUN]
        mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_RUN);
    }

    private void WaitEsp32Answer(Integer id) throws Exception {
        try {
            System.out.println("Waiting Esp32 Answer...");
            long startTime = System.nanoTime();
            while (this.GetFlagWeightNow() == 0 || this.GetFlagWifiStrengthNow() == 0) {
                long durationInSeconds = (System.nanoTime() - startTime) / 1_000_000_000;
                if (durationInSeconds < 5) System.out.print(".");
                else throw new Exception(String.format("Can't receive an answer of scale %d", id));
                Thread.sleep(Duration.ofMillis(200));
            }
        } finally {
            _globalFlagWifiStrengthNow = 1;
            _globalFlagWeightNow = 1;
        }
    }

    private void WaitTwoSeconds() throws Exception {
        System.out.println("Waiting Two Seconds");
        Thread.sleep(Duration.ofMillis(2000));
    }

    public WeightModel MeasureWeightViaMqtt(Integer id) throws Exception {
        var mac = GetMacFromScaleId(id);
        //Envio [MEA]
        this.SetFlagWeightNow(0);
        mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_MANUAL_MEASURE);

        this.WaitEsp32Answer(id);

        System.out.printf("Last weight received from esp32 %.2f %n", _lastManualMeasuredWeigth);
        var lastWeight = iWeight.findByScaleId(id).getLast();
        lastWeight.setWeightValue(_lastManualMeasuredWeigth);
        return lastWeight;
    }

    public boolean TareScaleViaMqtt(Integer id) throws Exception {
        var mac = this.GetMacFromScaleId(id);
        mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_TARE);
        this.WaitTwoSeconds();
        return true;
    }

    public WifiStrengthModel MeasureWifiStrengthViaMqtt(Integer id) throws Exception {
        var mac = GetMacFromScaleId(id);
        this.SetFlagWifiStrengthNow(0);
        mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_WIFI_STRENGTH);

        this.WaitEsp32Answer(id);

        var lastWifiStrength = iWifiStrength.findFirstByScaleIdOrderByWifiStrengthDateDesc(id)
                .orElseThrow(() -> new Exception(String.format("Can't find wifi strength from scale %d", id)));
        System.out.printf("Last wifi strength received from esp32 %d %n", lastWifiStrength.getWifiStrengthValue());
        return lastWifiStrength;
    }

    public boolean ChangeWifiViaMqtt(Integer id) throws Exception {
        var mac = this.GetMacFromScaleId(id);
        mqttPublisherService.sendCriticalCommand(mac, MQTT_COMMAND_CHANGE_WIFI);
        this.WaitTwoSeconds();
        return true;
    }

}
