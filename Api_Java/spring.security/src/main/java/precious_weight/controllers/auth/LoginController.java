package precious_weight.controllers.auth;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import precious_weight.auth.models.RoleModel;
import precious_weight.auth.interfaces.iUser;
import precious_weight.auth.models.UserModel;
import precious_weight.auth.models.request.LoginRequest;
import precious_weight.auth.models.response.LoginResponse;

import java.time.Instant;
import java.util.stream.Collectors;

import static precious_weight.config.system.ApiConstants.*;

@RestController
public class LoginController {

    private final JwtEncoder jwtEncoder;
    private final iUser iUser;
    private final BCryptPasswordEncoder passwordEncoder;

    public LoginController(JwtEncoder jwtEncoder, iUser iUser,
                           BCryptPasswordEncoder passwordEncoder) {
                                this.jwtEncoder = jwtEncoder;
                                this.iUser = iUser;
                                this.passwordEncoder = passwordEncoder;
                           }

    @PostMapping(LoginController)
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest loginRequest) {

        var user = iUser.findByEmail(loginRequest.getEmail());
        if (user.isEmpty() || !user.get().isLoginCorrect(loginRequest, passwordEncoder)) throw new ResponseStatusException(HttpStatus.BAD_REQUEST);

        var now = Instant.now();
        var expiresIn = 3000L;

        var scopes = user.get().getRoles()
                .stream()
                .map(RoleModel::getName)
                .collect(Collectors.joining(" "));

        var claims = JwtClaimsSet.builder()
                        .issuer(LoginController_BackEndName)
                        .subject(user.get().getUserId().toString())
                        .issuedAt(now)
                        .expiresAt(now.plusSeconds(expiresIn))
                        .claim(LoginController_Scope, scopes)
                        .build();

        var jwtValue = jwtEncoder.encode(JwtEncoderParameters.from(claims)).getTokenValue();

        return ResponseEntity.ok(new LoginResponse(jwtValue, expiresIn, user.get()));
    }


    @PostMapping(LoginController_ResetPass)
    public ResponseEntity<Void> resetPassword(@RequestBody LoginRequest request) {

        UserModel userFromDb;

        try {
            userFromDb = iUser.findByEmail(request.getEmail()).orElseThrow();
        }
        catch (Exception e){
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST);
        }

        userFromDb.setPassword(passwordEncoder.encode(request.getPassword()));
        iUser.save(userFromDb);
        return ResponseEntity.ok().build();
    }

}