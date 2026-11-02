package precious_weight.app.interfaces;

import precious_weight.app.models.BabyModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Set;

@Repository
public interface iBaby extends JpaRepository<BabyModel, Integer> {
}
