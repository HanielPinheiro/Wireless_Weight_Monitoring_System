package precious_weight.auth.interfaces;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import precious_weight.auth.models.RoleModel;

import java.util.Optional;

@Repository
public interface iRole extends JpaRepository<RoleModel, Long> {
    Optional<RoleModel> findByName(String role_Name);
}