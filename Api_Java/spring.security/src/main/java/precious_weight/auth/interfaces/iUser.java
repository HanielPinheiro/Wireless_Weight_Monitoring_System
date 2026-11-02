package precious_weight.auth.interfaces;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import precious_weight.auth.models.UserModel;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface iUser extends JpaRepository<UserModel, UUID> {
    Optional<UserModel> findByEmail(String username);
}