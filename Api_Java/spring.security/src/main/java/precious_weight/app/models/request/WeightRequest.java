package precious_weight.app.models.request;

import precious_weight.app.models.WeightModel;

import java.time.LocalDateTime;

public class WeightRequest {
    private Integer scaleId;
    private Integer babyId;
    private Double weightValue;

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

    public WeightModel ToModel(){
        WeightModel weightModel = new WeightModel();
        weightModel.setWeightDate(LocalDateTime.now());
        weightModel.setWeightValue(this.getWeightValue());
        weightModel.setScaleId(this.getScaleId());
        weightModel.setBabyId(this.getBabyId());
        return weightModel;
    }
}

