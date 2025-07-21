package com.bcp.rest;


import com.bcp.model.Expense;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;

import java.util.List;
import java.util.UUID;

@Path("/expenses")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class ExpenseResource {

    @GET
    // TODO 1: Implement with a call to "listAll()" of Expense entity.
    // TODO 2: Add pagination and sort by "amount" and "associateId".
    public List<Expense> list() {
        return null;
    }

    @POST
    // TODO: Make the method transactional
    public Expense create(final Expense expense) {
        Expense newExpense = Expense.of(expense.name, expense.paymentMethod,
                expense.amount.toString(), expense.associateId);
        // TODO: Use the "persist()" method of the entity.

        return newExpense;
    }

    @DELETE
    @Path("{uuid}")
    // TODO: Make the method transactional
    public void delete(@PathParam("uuid") final UUID uuid) {
        // TODO: Use the "delete()" method of the entity and list the expenses
    }

    @PUT
    // TODO: Make the method transactional
    public void update(final Expense expense) {
        // TODO: Use the "update()" method of the entity.
    }
}
