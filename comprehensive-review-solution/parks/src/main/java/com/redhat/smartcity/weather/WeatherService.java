package com.redhat.smartcity.weather;

import io.smallrye.mutiny.Uni;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

import java.util.List;

@Path("/warnings")
@RegisterRestClient(configKey = "weather-api")
public interface WeatherService {

    @GET
    @Path("/{city}")
    @Produces(MediaType.APPLICATION_JSON)
    Uni<List<WeatherWarning>> getWarningsByCity(@PathParam("city") String city);
}