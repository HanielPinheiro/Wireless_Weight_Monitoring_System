package precious_weight.app.models.request;

public class ScaleRequest {
    private Integer ScaleId;
    private Integer BabyId;

    public Integer getScaleId() {return ScaleId;}
    public void setScaleId(Integer scaleId) {ScaleId = scaleId;}

    public Integer getBabyId() {return BabyId;}
    public void setBabyId(Integer babyId) {BabyId = babyId;}

    @Override
    public String toString() {
        return "ScaleRequest{ScaleId=" + ScaleId +", BabyId=" + BabyId +'}';
    }
}
