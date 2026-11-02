package precious_weight.app.interfaces;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import precious_weight.app.models.WifiConnectivityModel;

import java.util.List;
import java.util.Optional;

@Repository
public interface iWifiConnectivity extends JpaRepository<WifiConnectivityModel, Integer> {
}
