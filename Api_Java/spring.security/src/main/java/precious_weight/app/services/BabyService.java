package precious_weight.app.services;

import precious_weight.app.models.ScaleModel;
import precious_weight.app.models.request.BabyRequest;
import precious_weight.auth.services.MqttPublisherService;
import precious_weight.app.models.BabyModel;
import precious_weight.app.interfaces.iBaby;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.sql.Blob;
import javax.sql.rowset.serial.SerialBlob;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class BabyService {
    public enum BabyStates {
        disabled(0), enabled(1);
        public final int value;

        BabyStates(int _value) {
            value = _value;
        }
    }

    @Autowired
    private iBaby iBaby;

    @Autowired
    private ScaleService scaleService;

    @Autowired
    private MqttPublisherService mqttPublisherService;

    public List<BabyModel> listAll() {
        return iBaby.findAll();
    }

    public BabyModel searchById(Integer id) throws Exception {
        Optional<BabyModel> baby = iBaby.findById(id);
        if (baby.isEmpty()) throw new Exception("Error when try to search baby by id");
        return baby.get();
    }

    public void uploadImage(Integer id, MultipartFile file) throws Exception {
        Blob scaleImage = new SerialBlob(file.getBytes());
        BabyModel babyModel = searchById(id);
        babyModel.setBabyImage(scaleImage);
        iBaby.save(babyModel);
    }

    public BabyModel enableOrDisable(Integer babyId, boolean enabled) throws Exception {
        // Verificar se existe balança vinculada ao bebe
        var babiesWithAndWithoutScales = listAll();
        var baby = babiesWithAndWithoutScales.stream().filter(s -> s.getBabyId().equals(babyId)).findFirst().orElse(null);

        // Se sim, retornar erro
        if (baby == null) throw new Exception("Error when try to enable or disable -> baby is null");
        if (baby.getAssignedScale() != null) throw new Exception("Error when try to enable or disable -> baby has scale");

        // Se não, prosseguir com a ação
        var val = enabled ? BabyStates.enabled.value : BabyStates.disabled.value;
        baby.setBabyState(val);
        return iBaby.save(baby);
    }

    public BabyModel NewOrUpdateScaleData(BabyRequest request) {
        return iBaby.save(new BabyModel(request));
    }

    public BabyModel update(Integer id, BabyRequest request) throws Exception {
        BabyModel babyModel = searchById(id);

        babyModel.setBabyHospitalId(request.getBabyHospitalId());
        babyModel.setBabyName(request.getBabyName());
        babyModel.setBabyMotherName(request.getBabyMotherName());
        babyModel.setBabyBirthDate(request.getBabyBirthDate());
        babyModel.setBabyImageText(request.getBabyImageText());

        if (request.getBabyWeightTime() != null && !Objects.equals(babyModel.getBabyWeightTime(), request.getBabyWeightTime())) {
            babyModel.setBabyWeightTime(request.getBabyWeightTime());
            if (babyModel.getAssignedScale() != null)
                scaleService.SendNewWeightTimesToScaleViaMqtt(id, request.getBabyWeightTime());
        }

        return iBaby.save(babyModel);
    }

    public byte[] GetQrCodeFromId(Integer id) {
        try {
            BabyModel model = iBaby.getReferenceById(id);
            Blob babyImage = model.getBabyImage();
            if (babyImage == null) throw new Exception("Do not exist qr code for this image");

            int blobLength = (int) babyImage.length();
            return babyImage.getBytes(1, blobLength);
        } catch (Exception e) {
            throw new RuntimeException("Failed to get Qr Code data", e);
        }
    }
}
