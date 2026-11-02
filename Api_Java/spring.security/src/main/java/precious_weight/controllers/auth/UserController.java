package precious_weight.controllers.auth;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import precious_weight.auth.models.RoleModel;
import precious_weight.auth.models.UserModel;
import precious_weight.auth.interfaces.iRole;
import precious_weight.auth.interfaces.iUser;
import precious_weight.auth.models.request.UserRequest;

import java.util.List;
import java.util.Set;

import static precious_weight.config.system.ApiConstants.*;



@RestController
@RequestMapping(UserController)
public class UserController {
    private final iUser iUser;
    private final iRole iRole;
    private final BCryptPasswordEncoder passwordEncoder;

    public UserController(iUser iUser, iRole iRole, BCryptPasswordEncoder passwordEncoder) {
        this.iUser = iUser;
        this.iRole = iRole;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping(Controller_New)
    public ResponseEntity<Void> newUser(@RequestBody UserRequest request) {
        var basicRole = iRole.findByName(RoleModel.Values.BASIC.name()).orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST));

        var userFromDb = iUser.findByEmail(request.getEmail());
        if (userFromDb.isPresent()) throw new ResponseStatusException(HttpStatus.BAD_REQUEST);

        var user = new UserModel();
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setOrganization(request.getOrganization());
        user.setRoles(Set.of(basicRole));

        iUser.save(user);

        return ResponseEntity.ok().build();
    }

    @PostMapping(Controller_List)
    @PreAuthorize("hasAuthority('SCOPE_ADMIN')")
    public ResponseEntity<List<UserModel>> listUsers() {
        return ResponseEntity.ok(iUser.findAll());
    }
}

