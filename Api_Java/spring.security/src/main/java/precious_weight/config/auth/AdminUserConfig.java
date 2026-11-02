package precious_weight.config.auth;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.DependsOn;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import precious_weight.auth.models.RoleModel;
import precious_weight.auth.models.UserModel;
import precious_weight.auth.interfaces.iRole;
import precious_weight.auth.interfaces.iUser;

import java.util.Set;

@Configuration
@DependsOn("authEntityManagerFactory")
public class AdminUserConfig implements CommandLineRunner {

    private final iRole authRoleInterface;
    private final iUser authUserInterface;
    private final BCryptPasswordEncoder passwordEncoder;

    public AdminUserConfig(iRole authRoleInterface, iUser authUserInterface, BCryptPasswordEncoder passwordEncoder) {
        this.authRoleInterface = authRoleInterface;
        this.authUserInterface = authUserInterface;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(String... args) throws Exception {

        var roleAdmin = authRoleInterface.findByName(RoleModel.Values.ADMIN.name());
        roleAdmin.ifPresentOrElse(
                role -> {/*Ignore*/},
                () -> {
                    // Create and save roles
                    RoleModel adminRoleModel = new RoleModel();
                    adminRoleModel.setName(RoleModel.Values.ADMIN.name());
                    authRoleInterface.save(adminRoleModel);

                    RoleModel basicRoleModel = new RoleModel();
                    basicRoleModel.setName(RoleModel.Values.BASIC.name());
                    authRoleInterface.save(basicRoleModel);
                }
        );

        var roleOfAdmin = authRoleInterface.findByName(RoleModel.Values.ADMIN.name()).orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST));

        var userAdmin = authUserInterface.findByEmail("teste@teste.com");
        userAdmin.ifPresentOrElse(
                userModel -> {/*Ignore*/},
                () -> {
                    var user = new UserModel();
                    user.setEmail("teste@teste.com");
                    user.setPassword(passwordEncoder.encode("123"));
                    user.setOrganization("Precious Weight");
                    user.setRoles(Set.of(roleOfAdmin));
                    authUserInterface.save(user);
                }
        );
    }
}