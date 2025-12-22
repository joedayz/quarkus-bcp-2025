package com.redhat.smartcity;


import io.smallrye.jwt.build.Jwt;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.jwt.Claims;

@ApplicationScoped
public class JwtGenerator {

    public String generateForUser(String username) {
        return Jwt.claims()
                .issuer("https://example.com/issuer")
                .claim(Claims.upn.name(), username)
                .claim(Claims.groups.name(), java.util.List.of("User", "Admin"))
                .sign();
    }
}
