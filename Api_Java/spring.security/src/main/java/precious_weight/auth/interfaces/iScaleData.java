package precious_weight.auth.interfaces;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import precious_weight.auth.models.ScaleDataModel;

import java.util.UUID;

@Repository
public interface iScaleData extends JpaRepository<ScaleDataModel, UUID> {
}

