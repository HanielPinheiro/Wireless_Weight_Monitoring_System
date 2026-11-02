package precious_weight.auth.models.request;

import java.util.UUID;

public class ScaleDataRequest {
    private UUID id;
    private String mac;
    private String pop;

    public ScaleDataRequest() {} // Default constructor (required for deserialization)

    public ScaleDataRequest(UUID id) {this.id = id;}

    public ScaleDataRequest(String mac) {this.mac = mac;}
    public ScaleDataRequest(String mac, String pop) {this.mac = mac; this.pop = pop;}

    public String getMac() {return mac;}
    public void setMac(String mac) {this.mac = mac;}

    public String getPop() {return this.pop;}
    public void setPop(String pop) {this.pop = pop;}

    public UUID getId() {return id;}
    public void setId(UUID id) {this.id = id;}
}


