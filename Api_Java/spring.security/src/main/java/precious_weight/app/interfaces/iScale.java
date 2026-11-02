package precious_weight.app.interfaces;

import precious_weight.app.models.ScaleModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface iScale extends JpaRepository<ScaleModel, Integer> {
    Optional<ScaleModel> findByScaleHash(String scaleHash);
}

