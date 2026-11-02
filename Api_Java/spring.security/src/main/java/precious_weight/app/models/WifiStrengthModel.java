package precious_weight.app.models;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.persistence.*;
import org.hibernate.envers.Audited;

import java.io.Serializable;
import java.time.LocalDateTime;

import static precious_weight.config.system.DataTransferLayerConstants.*;

@Entity
@Audited
@Table(name = App_WifiStrengthTable_TableName)
public class WifiStrengthModel implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = App_WifiStrengthTable_Id, nullable = false)
    private Integer wifiStrengthId;

    @Column(name = App_WifiStrengthTable_Date, nullable = false)
    @JsonFormat(timezone = "America/Sao_Paulo")
    private LocalDateTime wifiStrengthDate;

    @Column(name = App_ScaleTable_Id, nullable = false)
    private Integer scaleId;

    @Column(name = App_WifiStrengthTable_Value, nullable = false)
    private Integer wifiStrengthValue;

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
