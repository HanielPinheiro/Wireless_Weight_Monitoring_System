package precious_weight.controllers.app;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

import precious_weight.app.interfaces.iWeight;
import precious_weight.app.models.request.WeightRequest;
import static precious_weight.config.system.ApiConstants.*;

@RestController
@RequestMapping(WeightController)
public class WeightController {

    @Autowired
    iWeight iWeight;

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_List)
    public ResponseEntity<?> listAllWeights() {
        try {
            return ResponseEntity.ok(iWeight.findAll());
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Save)
    public ResponseEntity<?> saveWeight(@RequestBody WeightRequest request) {
        try {
            return ResponseEntity.ok(iWeight.save(request.ToModel()));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(WeightController_Babies)
    public ResponseEntity<?> getBabyWeights(@PathVariable Integer babyId) {
        try {
            return ResponseEntity.ok(iWeight.findByBabyId(babyId));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(WeightController_Scales)
    public ResponseEntity<?> getScaleWeights(@PathVariable Integer scaleId) {
        try {
            return ResponseEntity.ok(iWeight.findByScaleId(scaleId));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }
   
}
