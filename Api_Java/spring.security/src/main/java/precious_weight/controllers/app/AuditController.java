package precious_weight.controllers.app;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import precious_weight.app.models.BabyModel;
import precious_weight.app.models.ScaleModel;
import precious_weight.app.models.envers.AuditRepository;
import precious_weight.app.models.response.BabyResponse;
import precious_weight.app.models.response.ScaleResponse;

import java.util.List;
import java.util.stream.Collectors;

import static precious_weight.config.system.ApiConstants.*;

@RestController
@RequestMapping(AuditController)
public class AuditController {

    private final AuditRepository auditRepository;

    public AuditController(AuditRepository auditRepository) {
        this.auditRepository = auditRepository;
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(AuditController_Babies)
    public List<Object[]> getBabyAudit(@PathVariable Integer babyId) {
        var rawData = auditRepository.getBabyRevisions(babyId);
        return rawData.stream().map(item -> {
            Object[] r = new Object[3];
            BabyModel babyModel = (BabyModel) item[0];
            r[0] = new BabyResponse(babyModel);
            r[1] = item[1];
            r[2] = item[2];
            return r;
        }).collect(Collectors.toList());
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(AuditController_Scales)
    public List<Object[]> getScaleAudit(@PathVariable Integer scaleId) {
        var rawData = auditRepository.getScaleRevisions(scaleId);
        return rawData.stream().map(item -> {
            Object[] r = new Object[3];
            ScaleModel scaleModel = (ScaleModel) item[0];
            r[0] = new ScaleResponse(scaleModel);
            r[1] = item[1];
            r[2] = item[2];
            return r;
        }).collect(Collectors.toList());
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(AuditController_Weights)
    public List<Object[]> getWeightAudit(@PathVariable Integer babyId) {
        return auditRepository.getWeightRevisions(babyId);
    }
}