package precious_weight.app.models;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.persistence.*;
import org.hibernate.envers.Audited;

import java.io.Serializable;
import java.time.LocalDateTime;

import static precious_weight.config.system.DataTransferLayerConstants.*;

@Entity
@Audited
@Table(name = App_WeightTable_TableName)
public class WeightModel implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = App_WeightTable_Id, nullable = false)
    private Integer weightId;

    @Column(name = App_WeightTable_Date, nullable = false)
    @JsonFormat(timezone = "America/Sao_Paulo")
    private LocalDateTime weightDate;

    @Column(name = App_ScaleTable_Id, nullable = false)
    private Integer scaleId;

    @Column(name = App_BabyTable_Id, nullable = false)
    private Integer babyId;

    @Column(name = App_WeightTable_Value, nullable = false)
    private Double weightValue;

    public Integer getWeightId() {
        return weightId;
    }
    public void setWeightId(Integer weightId) {
        this.weightId = weightId;
    }

    public LocalDateTime getWeightDate() {
        return weightDate;
    }
    public void setWeightDate(LocalDateTime weightDate) {
        this.weightDate = weightDate;
    }

    public Integer getBabyId() {
        return babyId;
    }
    public void setBabyId(Integer babyId) {
        this.babyId = babyId;
    }

    public Integer getScaleId() {
        return scaleId;
    }
    public void setScaleId(Integer scaleId) {
        this.scaleId = scaleId;
    }

    public Double getWeightValue() {
        return weightValue;
    }
    public void setWeightValue(Double weightValue) {
        this.weightValue = weightValue;
    }
}

