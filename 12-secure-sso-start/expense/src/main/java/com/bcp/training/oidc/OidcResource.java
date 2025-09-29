package com.bcp.training.oidc;

import java.util.Set;

import jakarta.annotation.security.PermitAll;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;


import io.quarkus.security.identity.SecurityIdentity;
import org.jboss.resteasy.reactive.NoCache;


@Path( "/oidc" )
@Consumes( MediaType.APPLICATION_JSON )
@Produces( MediaType.APPLICATION_JSON )
public class OidcResource {

    @Inject
    SecurityIdentity securityIdentity;

    @GET
    @NoCache
    @PermitAll
    public User me() {
        return new User(securityIdentity);
    }

    public static class User {

        private Set<String> roles;

        User(SecurityIdentity securityIdentity) {
            this.roles = securityIdentity.getRoles();
        }

        public Set<String> getRoles() {
            return this.roles;
        }
    }
}