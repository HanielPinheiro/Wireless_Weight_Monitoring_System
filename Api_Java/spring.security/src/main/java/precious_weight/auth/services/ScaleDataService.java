package precious_weight.auth.services;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import precious_weight.app.models.ScaleModel;
import precious_weight.auth.interfaces.iScaleData;
import precious_weight.auth.models.ScaleDataModel;
import precious_weight.auth.models.request.ScaleDataRequest;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.security.SecureRandom;
import java.util.*;

@Service
public class ScaleDataService {
    @Autowired
    private iScaleData iScaleData;

    public ScaleDataModel NewOrUpdateScaleData(ScaleDataRequest scaleData) {
        UUID id = scaleData.getId();
        ScaleDataModel model = (id != null) ? GetScaleFromId(id) : new ScaleDataModel();
        model.setMac(scaleData.getMac());
        String userSetPop = scaleData.getPop();
        model.setPop(Objects.equals(userSetPop, "") || userSetPop == null ? generatePop() : userSetPop);
        return iScaleData.save(model);
    }

    public List<ScaleDataModel> GetScales() {
        return iScaleData.findAll();
    }

    public ScaleDataModel GetScaleFromId(UUID scaleId) {
        return GetScales().stream().filter(model -> model.getScaleId().equals(scaleId)).findFirst().orElse(null);
    }

    public byte[] GetQrCodeFromId(UUID scaleId) {
        try {// Convert BufferedImage to byte array
            BufferedImage qrImage = generateQRCodeImage(scaleId.toString());
            ByteArrayOutputStream arrayOfBytes = new ByteArrayOutputStream();
            ImageIO.write(qrImage, "PNG", arrayOfBytes);
            return arrayOfBytes.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate QR code", e);
        }
    }

    public ScaleDataModel GetScaleFromMac(String scaleMac) {
        return GetScales().stream().filter(model -> model.getMac().equals(scaleMac)).findFirst().orElse(null);
    }

    public ScaleDataModel GetScaleFromMac(UUID scaleId, String scaleMac) {
        return GetScales().stream().filter(model -> model.getMac().equals(scaleMac) && !model.getScaleId().equals(scaleId)).findFirst().orElse(null);
    }

    public String GetScaleMacFromScaleHashId(String scaleHashId) throws Exception {
        var result = GetScales().stream().filter(model -> model.getScaleId().equals(UUID.fromString(scaleHashId))).findFirst().orElse(null);
        if (result == null) throw new Exception("Scale Data not Found");
        return result.getMac();
    }

    private String generatePop() {
        String ALPHANUMERIC = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@$%*+-";
        int size = ALPHANUMERIC.length();
        SecureRandom random = new SecureRandom();
        StringBuilder sb = new StringBuilder(8);
        for (int i = 0; i < 8; i++) sb.append(ALPHANUMERIC.charAt(random.nextInt(size)));
        return sb.toString();
    }

    private BufferedImage generateQRCodeImage(String data) throws Exception {
        QRCodeWriter qrCodeWriter = new QRCodeWriter();
        BitMatrix bitMatrix = qrCodeWriter.encode(data, BarcodeFormat.QR_CODE, 250, 250);
        BufferedImage image = new BufferedImage(250, 250, BufferedImage.TYPE_INT_RGB);
        for (int x = 0; x < 250; x++)
            for (int y = 0; y < 250; y++)
                image.setRGB(x, y, bitMatrix.get(x, y) ? 0x000000 : 0xFFFFFF);
        return image;
    }
}
