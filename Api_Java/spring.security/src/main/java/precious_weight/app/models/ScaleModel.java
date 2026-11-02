package precious_weight.app.models;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.persistence.*;
import org.hibernate.envers.Audited;

import java.io.Serializable;
import java.time.LocalDateTime;

import static precious_weight.config.system.DataTransferLayerConstants.*;

@Entity
@Audited
@Table(name = App_ScaleTable_TableName)
public class ScaleModel implements Serializable {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = App_ScaleTable_Id, nullable = false)
    private Integer scaleId;

    @Column(name = App_ScaleTable_Hash, nullable = false, length = 255, unique = true)
    private String scaleHash;

    @Column(name = App_ScaleTable_State, nullable = false)
    private Integer scaleState;

    @Column(name = App_ScaleTable_IsConnected, nullable = false)
    private Boolean isConnected = false;

    @Column(name = App_ScaleTable_LastConnectedAt)
    @JsonFormat(timezone = "America/Sao_Paulo")
    private LocalDateTime lastConnectedAt;

    @Column(name = App_ScaleTable_LastDisconnectedAt)
    @JsonFormat(timezone = "America/Sao_Paulo")
    private LocalDateTime lastDisconnectedAt;

    @Column(name = App_ScaleTable_WifiStrength, nullable = false)
    private Integer wifiStrength;

    @OneToOne
    @JoinColumn(name = App_BabyTable_Id)  // Match your DB column
    private BabyModel assignedBaby;
    public BabyModel getAssignedBaby() {
        return assignedBaby;
    }
    public void setAssignedBaby(BabyModel baby) {this.assignedBaby = baby;}

    public Integer getScaleId() {
        return scaleId;
    }
    public void setScaleId(Integer scaleId) {
        this.scaleId = scaleId;
    }

    public String getScaleHash() {
        return scaleHash;
    }
    public void setScaleHash(String scaleHash) {this.scaleHash = scaleHash;}

    public Integer getScaleState() {
        return scaleState;
    }
    public void setScaleState(Integer scaleState) {
        this.scaleState = scaleState;
    }

    public Boolean getIsConnected() {
        return isConnected;
    }
    public void setIsConnected(Boolean connected) {
        isConnected = connected;
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
    public void setLastDisconnectedAt(LocalDateTime lastDisconnectedAt) {
        this.lastDisconnectedAt = lastDisconnectedAt;
    }

    public Integer getWifiStrength() {
        return wifiStrength;
    }
    public void setWifiStrength(Integer wifiStrength) {
        this.wifiStrength = wifiStrength;
    }
}


