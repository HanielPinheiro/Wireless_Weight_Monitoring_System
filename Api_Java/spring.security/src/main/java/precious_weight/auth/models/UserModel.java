package precious_weight.auth.models;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import precious_weight.auth.models.request.LoginRequest;

import java.util.Set;
import java.util.UUID;

import static precious_weight.config.system.DataTransferLayerConstants.*;

@Entity
@Table(name = Auth_UserTable_TableName)
public class UserModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = Auth_UserTable_Id, nullable = false)
    private UUID userId;

    @Column(name = Auth_UserTable_Email, nullable = false, unique = true)
    private String email;

    @Column(name = Auth_UserTable_Password, nullable = false)
    @JsonIgnore
    private String password;

    @Column(name = Auth_UserTable_Organization, nullable = false)
    private String organization;

    @ManyToMany(cascade = CascadeType.MERGE, fetch = FetchType.EAGER)
    @JoinTable(
            name= Auth_UserRoleRel_TableName,
            joinColumns = @JoinColumn(name = Auth_UserTable_Id),
            inverseJoinColumns = @JoinColumn(name = Auth_RoleTable_Id)
    )
    private Set<RoleModel> roleModels;

    public UUID getUserId() {
        return userId;
    }
    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getEmail() {
        return email;
    }
    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }
    public void setPassword(String password) {
        this.password = password;
    }

    public String getOrganization() {
        return organization;
    }
    public void setOrganization(String organization) {
        this.organization = organization;
    }

    public Set<RoleModel> getRoles() {
        return roleModels;
    }
    public void setRoles(Set<RoleModel> roleModels) {
        this.roleModels = roleModels;
    }

    public boolean isLoginCorrect(LoginRequest loginRequest, PasswordEncoder passwordEncoder) {
        return passwordEncoder.matches(loginRequest.getPassword(), this.password);
    }
}
