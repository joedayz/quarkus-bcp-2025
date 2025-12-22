package com.redhat.smartcity;

import io.smallrye.mutiny.Uni;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;

@Path("/parks")
@Tag(name = "Parks", description = "Operaciones para gestionar parques")
public class ParksResource {

    @Inject
    ParkGuard guard;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Listar todos los parques",
            description = "Obtiene una lista de todos los parques registrados")
    public List<Park> getAllParks() {
        return Park.listAll();
    }

    @PUT
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @RolesAllowed("Admin")
    @Operation(summary = "Actualizar un parque",
            description = "Actualiza la información de un parque existente. Requiere rol Admin.")
    @Transactional
    public Park updatePark(Park park) {
        Park entity = Park.findById(park.id);
        if (entity == null) {
            throw new NotFoundException();
        }
        entity.name = park.name;
        entity.city = park.city;
        entity.status = park.status;
        return entity;
    }

    @POST
    @Path("/{id}/weathercheck")
    @Transactional
    public Uni<Void> checkWeather(@PathParam("id") Long id) {
        return Park
                .<Park>findByIdOptional(id)
                .map(guard::checkWeatherForPark)
                .orElseThrow(NotFoundException::new);
    }
}