package com.bcp.service;

import com.bcp.client.ExpenseServiceClient;
import com.bcp.model.Expense;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.rest.client.inject.RestClient;


import java.util.Set;

@Path("/expenses")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class ClientResource {

    @Inject
    @RestClient
    ExpenseServiceClient service;

    @GET
    public Set<Expense> getAll() {
        return service.getAll();
    }

    @POST
    public Expense create(Expense expense) {
        return service.create(expense);
    }
}
