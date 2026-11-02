package precious_weight.app.interfaces;

import precious_weight.app.models.WeightModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface iWeight extends JpaRepository<WeightModel, Integer> {
    // O Spring gera automaticamente a consulta: SELECT * FROM weight WHERE baby_id = ?
    List<WeightModel> findByBabyId(Integer babyId);

    // O Spring gera automaticamente a consulta: SELECT * FROM weight WHERE scale_id = ?
    List<WeightModel> findByScaleId(Integer scaleId);
}
