package precious_weight.app.models.response;

import precious_weight.app.models.BabyModel;
import java.time.LocalDate;

public class BabyResponse {
    private Integer babyId;
    private String babyName;
    private String babyMotherName;
    private LocalDate babyBirthDate;
    private Integer babyState;
    private String babyWeightTime;
    private String babyHospitalId;
    private String babyImageText;
    private boolean babyImageQr;
    private Integer scaleId;

    public BabyResponse() {}

    public BabyResponse(BabyModel model) {
        this.babyId = model.getBabyId();
        this.babyName = model.getBabyName();
        this.babyMotherName = model.getBabyMotherName();
        this.babyBirthDate = model.getBabyBirthDate();
        this.babyState = model.getBabyState();
        this.babyWeightTime = model.getBabyWeightTime();
        this.babyHospitalId = model.getBabyHospitalId();
        this.babyImageText = model.getBabyImageText();
        this.babyImageQr = model.getBabyImageText() == null;
        this.scaleId = model.getAssignedScale() != null ? model.getAssignedScale().getScaleId() : null;
    }

    public Integer getBabyId() {
        return babyId;
    }

    public void setBabyId(Integer babyId) {
        this.babyId = babyId;
    }

    public String getBabyName() {
        return babyName;
    }

    public void setBabyName(String babyName) {
        this.babyName = babyName;
    }

    public String getBabyMotherName() {
        return babyMotherName;
    }

    public void setBabyMotherName(String babyMotherName) {
        this.babyMotherName = babyMotherName;
    }

    public LocalDate getBabyBirthDate() {
        return babyBirthDate;
    }

    public void setBabyBirthDate(LocalDate babyBirthDate) {
        this.babyBirthDate = babyBirthDate;
    }

    public Integer getBabyState() {
        return babyState;
    }

    public void setBabyState(Integer babyState) {
        this.babyState = babyState;
    }

    public String getBabyWeightTime() {
        return babyWeightTime;
    }

    public void setBabyWeightTime(String babyWeightTime) {
        this.babyWeightTime = babyWeightTime;
    }

    public String getBabyHospitalId() {
        return babyHospitalId;
    }

    public void setBabyHospitalId(String babyHospitalId) {
        this.babyHospitalId = babyHospitalId;
    }

    public String getBabyImageText() {
        return babyImageText;
    }

    public void setBabyImageText(String babyImageText) {
        this.babyImageText = babyImageText;
    }

    public Integer getScaleId() {
        return scaleId;
    }

    public void setScaleId(Integer scaleId) {
        this.scaleId = scaleId;
    }

    public boolean isBabyImageQr() {
        return babyImageQr;
    }

    public void setBabyImageQr(boolean babyImageQr) {
        this.babyImageQr = babyImageQr;
    }

    @Override
    public String toString() {
        return "BabyResponse{" +
                "babyId=" + babyId +
                ", babyName='" + babyName + '\'' +
                ", babyMotherName='" + babyMotherName + '\'' +
                ", babyBirthDate=" + babyBirthDate +
                ", babyState=" + babyState +
                ", babyWeightTime='" + babyWeightTime + '\'' +
                ", babyHospitalId='" + babyHospitalId + '\'' +
                ", babyImageText='" + babyImageText + '\'' +
                ", babyImageQr=" + babyImageQr +
                ", scaleId=" + scaleId +
                '}';
    }
}
