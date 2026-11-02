package precious_weight.controllers.app;

import precious_weight.app.models.ScaleModel;
import precious_weight.app.models.request.ScaleRequest;
import precious_weight.app.models.response.ScaleResponse;
import precious_weight.app.models.response.WifiStrengthResponse;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import precious_weight.app.services.ScaleService;

import java.util.*;

import static precious_weight.config.system.ApiConstants.*;

@RestController
@RequestMapping(ScaleController)
public class ScaleController {

    @Autowired
    private ScaleService scaleService;

    /**
     ******************************************************************************************
     * CRUD OPERATIONS IN API AND DATABASE
     * ******************************************************************************************
     */

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_List)
    public ResponseEntity<?> listAll() {
        try {
            return ResponseEntity.ok(scaleService.GetScales().stream().map(ScaleResponse::new).toList());
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Search)
    public ResponseEntity<?> getById(@PathVariable Integer id) {
        try {
            ScaleModel model = scaleService.GetScaleFromId(id);
            return model != null ? ResponseEntity.ok(new ScaleResponse(model)) : ResponseEntity.notFound().build();
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Enable)
    public ResponseEntity<?> enableScale(@PathVariable Integer id) {
        try {
            return ResponseEntity.ok(new ScaleResponse(scaleService.EnableOrDisable(id, true)));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(Controller_Disable)
    public ResponseEntity<?> disableScale(@PathVariable Integer id) {
        try {
            return ResponseEntity.ok(new ScaleResponse(scaleService.EnableOrDisable(id, false)));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleController_SearchByHash)
    public ResponseEntity<?> getByHash(@PathVariable UUID hashId) {
        try {
            ScaleModel model = scaleService.GetScaleFromHash(hashId.toString());
            return model != null ?ResponseEntity.ok(new ScaleResponse(model)): ResponseEntity.notFound().build();
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleController_SetScaleToUser)
    public ResponseEntity<?> scaleToUser(@PathVariable UUID id) {
        try {
            return ResponseEntity.ok(new ScaleResponse(scaleService.SetScaleToUser(id)));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleController_SetBaby)
    public ResponseEntity<?> setBaby(@RequestBody ScaleRequest model) {
        try {
            return ResponseEntity.ok(new ScaleResponse(scaleService.SetOrUnsetBabyToScale(model, true)));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleController_UnsetBaby)
    public ResponseEntity<?> unsetBaby(@RequestBody ScaleRequest model) {
        try {
            return ResponseEntity.ok(new ScaleResponse(scaleService.SetOrUnsetBabyToScale(model, false)));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     ******************************************************************************************
     * Commands to mqtt
     * ******************************************************************************************
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleController_Measure)
    public ResponseEntity<?> measureWeight(@PathVariable Integer scaleId) {
        try {
            return ResponseEntity.ok(scaleService.MeasureWeightViaMqtt(scaleId));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleController_Tare)
    public ResponseEntity<?> tare(@PathVariable Integer scaleId) {
        try {
            return ResponseEntity.ok(scaleService.TareScaleViaMqtt(scaleId));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleController_WifiStrength)
    public ResponseEntity<?> measureWifiStrength(@PathVariable Integer scaleId) {
        try {
            return ResponseEntity.ok(new WifiStrengthResponse(scaleService.MeasureWifiStrengthViaMqtt(scaleId)));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping(ScaleController_ChangeWifi)
    public ResponseEntity<?> changeWifi(@PathVariable Integer scaleId) {
        try {
            return ResponseEntity.ok(scaleService.ChangeWifiViaMqtt(scaleId));
        } catch (Exception ex) {
            Map<String, String> error = Map.of("error", ex.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }


}
