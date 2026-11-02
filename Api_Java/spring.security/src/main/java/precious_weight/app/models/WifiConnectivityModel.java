package precious_weight.app.models;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.persistence.*;
import org.hibernate.envers.Audited;

import java.io.Serializable;
import java.time.LocalDateTime;

import static precious_weight.config.system.DataTransferLayerConstants.*;

@Entity
@Audited
@Table(name = App_WifiConnectivity_TableName)
public class WifiConnectivityModel implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = App_WifiConnectivity_Id, nullable = false)
    private Integer wifiConnectivityId;

    @Column(name = App_WifiConnectivity_Date, nullable = false)
    @JsonFormat(timezone = "America/Sao_Paulo")
    private LocalDateTime wifiConnectivityDate;

    @Column(name = App_ScaleTable_Id, nullable = false)
    private Integer scaleId;

    @Column(name = App_WifiConnectivity_Value, nullable = false)
    private String wifiConnectivityValue;

    public WifiConnectivityModel(Integer scaleId, boolean connectivity) {
        this.wifiConnectivityValue = connectivity ? "CONNECTED" : "DISCONNECTED";
        this.wifiConnectivityDate = LocalDateTime.now();
        this.scaleId = scaleId;
    }

    public Integer getWifiConnectivityId() {
        return wifiConnectivityId;
    }

    public void setWifiConnectivityId(Integer wifiConnectivityId) {
        this.wifiConnectivityId = wifiConnectivityId;
    }

    public LocalDateTime getWifiConnectivityDate() {
        return wifiConnectivityDate;
    }

    public void setWifiConnectivityDate(LocalDateTime wifiConnectivityDate) {
        this.wifiConnectivityDate = wifiConnectivityDate;
    }

    public Integer getScaleId() {
        return scaleId;
    }

    public void setScaleId(Integer scaleId) {
        this.scaleId = scaleId;
    }

    public String getWifiConnectivityValue() {
        return wifiConnectivityValue;
    }

    public void setWifiConnectivityValue(String wifiConnectivityValue) {
        this.wifiConnectivityValue = wifiConnectivityValue;
    }
}
