package precious_weight.app.models.request;

import java.time.LocalDate;

public class BabyRequest {
    private Integer babyId;
    private String babyName;
    private String babyMotherName;
    private LocalDate babyBirthDate;
    private Integer babyState;
    private String babyWeightTime;
    private String babyHospitalId;
    private String babyImageText;

    public Integer getBabyId() {return babyId;}
    public void setBabyId(Integer babyId) {this.babyId = babyId;}

    public String getBabyName() {return babyName;}
    public void setBabyName(String babyName) {this.babyName = babyName;}

    public String getBabyMotherName() {return babyMotherName;}
    public void setBabyMotherName(String babyMotherName) {this.babyMotherName = babyMotherName;}

    public LocalDate getBabyBirthDate() {return babyBirthDate;}
    public void setBabyBirthDate(LocalDate babyBirthDate) {this.babyBirthDate = babyBirthDate;}

    public Integer getBabyState() {return babyState;}
    public void setBabyState(Integer babyState) {this.babyState = babyState;}

    public String getBabyWeightTime() {return babyWeightTime;}
    public void setBabyWeightTime(String babyWeightTime) {this.babyWeightTime = babyWeightTime;}

    public String getBabyHospitalId() {return babyHospitalId;}
    public void setBabyHospitalId(String babyHospitalId) {this.babyHospitalId = babyHospitalId;}

    public String getBabyImageText() {return babyImageText;}
    public void setBabyImageText(String babyImageText) {this.babyImageText = babyImageText;}

    @Override
    public String toString() {
        return "BabyRequest{" +
                "babyId=" + babyId +
                ", babyName='" + babyName + '\'' +
                ", babyMotherName='" + babyMotherName + '\'' +
                ", babyBirthDate=" + babyBirthDate +
                ", babyState=" + babyState +
                ", babyWeightTime='" + babyWeightTime + '\'' +
                ", babyHospitalId='" + babyHospitalId + '\'' +
                ", babyImageText='" + babyImageText + '\'' +
                '}';
    }

}


