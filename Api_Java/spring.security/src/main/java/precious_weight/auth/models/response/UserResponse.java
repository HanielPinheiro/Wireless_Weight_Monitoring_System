package precious_weight.auth.models.response;

import precious_weight.auth.models.RoleModel;
import precious_weight.auth.models.UserModel;

import java.util.Objects;
import java.util.Set;
import java.util.UUID;

public class UserResponse {
    private String email;
    private String organization;
    private Set<RoleModel> roles;

    public UserResponse() {}

    public UserResponse(UserModel model) {
        this.email = model.getEmail();
        this.organization = model.getOrganization();
        this.roles = model.getRoles();
    }

    @Override
    public String toString() {
        return "UserResponse{email='" + email + '\'' +
                ", organization='" + organization + '\'' +
                ", roles=" + roles +'}';
    }

    public Set<RoleModel> getRoles() {return roles;}
    public void setRoles(Set<RoleModel> roles) {this.roles = roles;}

    public String getOrganization() {return organization;}
    public void setOrganization(String organization) {this.organization = organization;}

    public String getEmail() {return email;}
    public void setEmail(String email) {this.email = email;}
}
