package precious_weight.app.models.response;

import precious_weight.app.models.ScaleModel;

import java.time.LocalDateTime;

public class ScaleResponse {
    private Integer scaleId;
    private String scaleHash;
    private Integer scaleState;
    private Integer babyId;
    private boolean connectionStatus;
    private LocalDateTime lastConnectedAt;
    private LocalDateTime lastDisconnectedAt;
    private Integer wifiStrength;

    public ScaleResponse(){}

    public ScaleResponse(ScaleModel model) {
        this.scaleId = model.getScaleId();
        this.scaleHash = model.getScaleHash();
        this.scaleState = model.getScaleState();
        this.babyId = model.getAssignedBaby() != null ? model.getAssignedBaby().getBabyId() : null;
        this.connectionStatus = Boolean.TRUE.equals(model.getIsConnected()) ? true : false;
        this.lastConnectedAt = model.getLastConnectedAt();
        this.lastDisconnectedAt = model.getLastDisconnectedAt();
        this.wifiStrength = model.getWifiStrength();
    }

    public Integer getScaleId() {
        return scaleId;
    }
    public void setScaleId(Integer scaleId) {
        this.scaleId = scaleId;
    }

    public String getScaleHash() {
        return scaleHash;
    }
    public void setScaleHash(String scaleHash) {
        this.scaleHash = scaleHash;
    }

    public Integer getScaleState() {
        return scaleState;
    }
    public void setScaleState(Integer scaleState) {
        this.scaleState = scaleState;
    }

    public Integer getBabyId() {
        return babyId;
    }
    public void setBabyId(Integer babyId) {
        this.babyId = babyId;
    }

    public boolean getConnectionStatus() {
        return connectionStatus;
    }
    public void setConnectionStatus(boolean connectionStatus) {
        this.connectionStatus = connectionStatus;
    }

    public LocalDateTime getLastConnectedAt() {
        return lastConnectedAt;
    }
    public void setLastConnectedAt(LocalDateTime lastConnectedAt) {
        this.lastConnectedAt = lastConnectedAt;
    }

    public LocalDateTime getLastDisconnectedAt() {
        return lastDisconnectedAt;
    }
    public void setLastDisconnectedAt(LocalDateTime lastDisconnectedAt) {this.lastDisconnectedAt = lastDisconnectedAt;}

    public Integer getWifiStrength() {
        return wifiStrength;
    }
    public void setWifiStrength(Integer wifiStrength) {
        this.wifiStrength = wifiStrength;
    }

    @Override
    public String toString() {
        return "ScaleResponse{" +
                "scaleId=" + scaleId +
                ", scaleHash='" + scaleHash + '\'' +
                ", scaleState=" + scaleState +
                ", babyId=" + babyId +
                ", connectionStatus='" + connectionStatus + '\'' +
                ", lastConnectedAt=" + lastConnectedAt +
                ", lastDisconnectedAt=" + lastDisconnectedAt +
                ", wifiStrength='" + wifiStrength +
                '}';
    }
}
