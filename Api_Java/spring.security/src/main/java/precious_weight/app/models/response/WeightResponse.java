package precious_weight.app.models.response;

import precious_weight.app.models.WeightModel;
import java.time.LocalDateTime;

public class WeightResponse {
    private Integer weightId;
    private LocalDateTime weightDate;
    private Integer scaleId;
    private Integer babyId;
    private Double weightValue;

    public WeightResponse(){}

    public WeightResponse(WeightModel model) {
        this.weightId = model.getWeightId();
        this.weightDate = model.getWeightDate();
        this.scaleId = model.getScaleId();
        this.babyId = model.getBabyId();
        this.weightValue = model.getWeightValue();
    }

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

    public Integer getScaleId() {
        return scaleId;
    }

    public void setScaleId(Integer scaleId) {
        this.scaleId = scaleId;
    }

    public Integer getBabyId() {
        return babyId;
    }

    public void setBabyId(Integer babyId) {
        this.babyId = babyId;
    }

    public Double getWeightValue() {
        return weightValue;
    }

    public void setWeightValue(Double weightValue) {
        this.weightValue = weightValue;
    }

    @Override
    public String toString() {
        return "WeightResponse{" +
                "weightId=" + weightId +
                ", weightDate=" + weightDate +
                ", scaleId=" + scaleId +
                ", babyId=" + babyId +
                ", weightValue=" + weightValue +
                '}';
    }
}
