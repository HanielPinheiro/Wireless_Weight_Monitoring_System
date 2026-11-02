package precious_weight.app.models;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import org.hibernate.envers.Audited;
import org.hibernate.envers.NotAudited;
import precious_weight.app.models.request.BabyRequest;

import java.io.Serializable;
import java.sql.Blob;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.Base64;

import static precious_weight.config.system.DataTransferLayerConstants.*;

@Entity
@Audited
@Table(name = App_BabyTable_TableName)
public class BabyModel implements Serializable {
    public BabyModel(){}

    public BabyModel(BabyRequest request) {
        this.babyId = request.getBabyId();
        this.babyName = request.getBabyName();
        this.babyMotherName = request.getBabyMotherName();
        this.babyBirthDate = request.getBabyBirthDate();
        this.babyState = request.getBabyState();
        this.babyWeightTime = request.getBabyWeightTime();
        this.babyHospitalId = request.getBabyHospitalId();
        this.babyImageText = request.getBabyImageText();
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = App_BabyTable_Id)
    private Integer babyId;

    @Column(name = App_BabyTable_Name)
    private String babyName;

    @Column(name = App_BabyTable_MotherName)
    private String babyMotherName;

    @Column(name = App_BabyTable_BirthDate)
    @JsonFormat(pattern = "yyyy-MM-dd", timezone = "America/Sao_Paulo")
    private LocalDate babyBirthDate;

    @Column(name = App_BabyTable_State)
    private Integer babyState;

    @Column(name = App_BabyTable_WeightHour)
    private String babyWeightTime;

    @Column(name = App_BabyTable_HospitalId, nullable = false, length = 255, unique = true)
    private String babyHospitalId;

    @Column(name = App_BabyTable_ImageText)
    private String babyImageText;

    @NotAudited
    @JsonIgnore
    @Column(name = App_BabyTable_Image, nullable = true, unique = true)
    private Blob babyImage;

    public String getBabyImageAs64() throws SQLException {
        if (babyImage == null) return "";
        int blobLength = (int) babyImage.length();
        byte[] blobAsBytes = babyImage.getBytes(1, blobLength);
        return Base64.getEncoder().encodeToString(blobAsBytes);
    }

    @OneToOne(mappedBy = "assignedBaby", fetch = FetchType.LAZY)
    private ScaleModel assignedScale;
    public ScaleModel getAssignedScale() {return assignedScale;}
    public void setAssignedScale(ScaleModel scale) {this.assignedScale = scale;}

    public Integer getBabyId() {
        return babyId;
    }
    public void setBabyId(Integer babyId) {
        this.babyId = babyId;
    }

    public String getBabyName() { return babyName; }
    public void setBabyName(String name) {
        this.babyName = name;
    }

    public String getBabyMotherName() {
        return babyMotherName;
    }
    public void setBabyMotherName(String motherName) {
        this.babyMotherName = motherName;
    }

    public LocalDate getBabyBirthDate() { return babyBirthDate; }
    public void setBabyBirthDate(LocalDate birthDate) {
        this.babyBirthDate = birthDate;
    }

    public Integer getBabyState() {return babyState;}
    public void setBabyState(Integer state) {this.babyState = state;}

    public String getBabyWeightTime() {return babyWeightTime;}
    public void setBabyWeightTime(String weightHour) {this.babyWeightTime = weightHour;}

    public String getBabyImageText() {return babyImageText;}
    public void setBabyImageText(String imageText) {this.babyImageText = imageText;}

    public String getBabyHospitalId() {return babyHospitalId;}
    public void setBabyHospitalId(String babyHospitalId) {this.babyHospitalId = babyHospitalId;}

    public Blob getBabyImage() {
        return babyImage;
    }
    public void setBabyImage(Blob babyImage) {
        this.babyImage = babyImage;
    }
}
