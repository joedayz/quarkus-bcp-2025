package com.bcp.rest;

import io.quarkus.test.common.QuarkusTestResourceConfigurableLifecycleManager;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;


import java.util.Map;

public class PostgresDBTestResource implements QuarkusTestResourceConfigurableLifecycleManager<WithPostgresDB> {

    private static final DockerImageName imageName =DockerImageName.parse("postgres:14.1")
            .asCompatibleSubstituteFor("postgres");

    private static final PostgreSQLContainer<?> DATABASE  = new PostgreSQLContainer<>(imageName);

    private String name;
    private String username;
    private String password;

    @Override
    public void init(WithPostgresDB params) {
        username = params.username();
        password = params.password();
        name = params.name();
    }

    @Override
    public Map<String, String> start() {
        DATABASE.withDatabaseName(name).withUsername(username).withPassword(password).start();
        return Map.of(
                "quarkus.datasource.username", username,
                "quarkus.datasource.password", password,
                "quarkus.datasource.jdbc.url", DATABASE.getJdbcUrl()
        );
    }

    @Override
    public void stop() {
        DATABASE.stop();
    }


}
