package precious_weight.auth.models;

import jakarta.persistence.*;

import java.sql.Blob;
import java.util.UUID;

import static precious_weight.config.system.DataTransferLayerConstants.*;

@Entity
@Table(name = Auth_ScaleTable_TableName)
public class ScaleDataModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = Auth_ScaleTable_Id, nullable = false)
    private UUID scaleId;

    @Column(name = Auth_ScaleTable_Mac)
    private String mac;

    @Column(name = Auth_ScaleTable_Pop)
    private String pop;

    @Column(name = Auth_ScaleTable_QrCode)
    private Blob qrCode;

    public UUID getScaleId() { return scaleId; }
    public void setScaleId(UUID scaleId) { this.scaleId = scaleId; }

    public String getMac() { return mac; }
    public void setMac(String mac) { this.mac = mac; }

    public String getPop() {return pop;}
    public void setPop(String pop) {this.pop = pop;}

    public Blob getQrCode() { return qrCode; }
    public void setQrCode(Blob qrCode) { this.qrCode = qrCode; }

    @Override
    public String toString() {
        return "AuthScaleModel{ scaleId=" + scaleId + ", mac='" + mac + '\'' + ", pop='" + pop + '\'' + ", qrCode=" + qrCode + '}';
    }
}
