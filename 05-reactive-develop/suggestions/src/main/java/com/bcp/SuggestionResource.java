package com.bcp;

import io.quarkus.hibernate.reactive.panache.common.WithTransaction;
import io.smallrye.mutiny.Uni;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;

@Path("/suggestion")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class SuggestionResource {

    @POST
    @WithTransaction
    public Uni<Suggestion> create(Suggestion newSuggestion) {
        return newSuggestion.persist();
    }

    @GET
    @Path("/{id}")
    public Uni<Suggestion> get(Long id){
        return Suggestion.findById(id);
    }

    @DELETE
    public Uni<Long> deleteAll() {
        return Suggestion.deleteAll();
    }
}
