package precious_weight.auth.models.response;

import precious_weight.auth.models.ScaleDataModel;

import java.util.UUID;

public class ScaleDataResponse {
     private UUID scaleId;
    private String mac;
    private String pop;

    public ScaleDataResponse(ScaleDataModel model) {
        this.scaleId = model.getScaleId();
        this.mac = model.getMac();
        this.pop = model.getPop();
    }

    public UUID getScaleId() {
        return scaleId;
    }

    @Override
    public String toString() {
        return "ScaleDataResponse{scaleId=" + scaleId +", mac='" + mac + '\'' +", pop='" + pop + '\'' +'}';
    }

    public String getMac() {
        return mac;
    }

    public String getPop() {
        return pop;
    }
}
