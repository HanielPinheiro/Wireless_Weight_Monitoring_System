package precious_weight.app.models.response;

import precious_weight.app.models.WifiStrengthModel;

import java.time.LocalDateTime;

public class WifiStrengthResponse {
    private Integer wifiStrengthId;
    private LocalDateTime wifiStrengthDate;
    private Integer scaleId;
    private Integer wifiStrengthValue;

    public WifiStrengthResponse() {}

    public WifiStrengthResponse(WifiStrengthModel model) {
        this.wifiStrengthId = model.getWifiStrengthId();
        this.wifiStrengthDate = model.getWifiStrengthDate();
        this.scaleId = model.getScaleId();
        this.wifiStrengthValue = model.getWifiStrengthValue();
    }

    public Integer getWifiStrengthId() {
        return wifiStrengthId;
    }

    public void setWifiStrengthId(Integer wifiStrengthId) {
        this.wifiStrengthId = wifiStrengthId;
    }

    public LocalDateTime getWifiStrengthDate() {
        return wifiStrengthDate;
    }

    public void setWifiStrengthDate(LocalDateTime wifiStrengthDate) {
        this.wifiStrengthDate = wifiStrengthDate;
    }

    public Integer getScaleId() {
        return scaleId;
    }

    public void setScaleId(Integer scaleId) {
        this.scaleId = scaleId;
    }

    public Integer getWifiStrengthValue() {
        return wifiStrengthValue;
    }

    public void setWifiStrengthValue(Integer wifiStrengthValue) {
        this.wifiStrengthValue = wifiStrengthValue;
    }
}
