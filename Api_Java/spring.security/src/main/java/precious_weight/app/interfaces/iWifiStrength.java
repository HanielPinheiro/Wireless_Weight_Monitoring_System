package precious_weight.app.interfaces;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import precious_weight.app.models.WifiStrengthModel;

import java.util.List;
import java.util.Optional;

@Repository
public interface iWifiStrength extends JpaRepository<WifiStrengthModel, Integer> {
    List<WifiStrengthModel> findByScaleId(Integer scaleId);

    Optional<WifiStrengthModel> findFirstByScaleIdOrderByWifiStrengthDateDesc(Integer scaleId);
}
