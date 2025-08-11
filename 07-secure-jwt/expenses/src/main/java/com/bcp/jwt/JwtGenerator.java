package com.bcp.jwt;

import java.util.Arrays;
import java.util.HashSet;
import java.util.List;

import io.smallrye.jwt.build.Jwt;

public class JwtGenerator {

    private static final String ISSUER = "https://example.com/bcptraining";

    public static String generateJwtForRegularUser( String username ) {
        return Jwt.issuer( ISSUER )
                .upn( username + "@example.com" )
                .subject( username )
                .audience("expenses.example.com")
                .claim("locale", "en_US")
                .groups(new HashSet<>(List.of("USER")))
                .sign();
    }

    public static String generateJwtForAdmin( String username ) {
        return Jwt.issuer( ISSUER )
                .upn( username + "@example.com" )
                .subject( username )
                .claim( "locale", "en_US" )
                .groups(new HashSet<>(List.of("USER", "ADMIN")))
                .sign();
    }
}