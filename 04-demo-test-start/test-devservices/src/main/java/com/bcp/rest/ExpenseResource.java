package com.bcp.rest;



import com.bcp.model.Expense;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.panache.common.Page;
import io.quarkus.panache.common.Sort;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.List;
import java.util.UUID;

@Path("/expenses")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class ExpenseResource {

    @GET
    public List<Expense> list(@DefaultValue("5") @QueryParam("pageSize") int pageSize,
                              @DefaultValue("1") @QueryParam("pageNum") int pageNum) {
        PanacheQuery<Expense> expenseQuery = Expense.findAll(
                Sort.by("amount").and("associateId"));
        return expenseQuery.page(Page.of(pageNum - 1, pageSize)).list();
    }

    @POST
    @Transactional
    public Expense create(final Expense expense) {
        Expense newExpense = Expense.of(expense.name, expense.paymentMethod,
                expense.amount.toString(), expense.associateId);
        // TODO: Use the "persist()" method of the entity.
        newExpense.persist();

        return newExpense;
    }

    @DELETE
    @Path("{uuid}")
    @Transactional
    public List<Expense> delete(@PathParam("uuid") final UUID uuid) {
        long numExpensesDeleted = Expense.delete("uuid", uuid);

        if (numExpensesDeleted == 0) {
            throw new WebApplicationException(Response.Status.NOT_FOUND);
        }

        return Expense.listAll();
    }

    @PUT
    @Transactional
    public void update(final Expense expense) {
        try {
            Expense.update(expense);
        } catch (RuntimeException e) {
            throw new WebApplicationException(Response.Status.NOT_FOUND);
        }
    }
}