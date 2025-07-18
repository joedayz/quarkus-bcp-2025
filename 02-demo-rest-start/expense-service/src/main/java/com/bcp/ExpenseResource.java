package com.bcp;

import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.Set;
import java.util.UUID;

@Path("/expenses")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class ExpenseResource {

    @Inject
    public ExpenseService expenseService;

    /**
     * curl -X GET http://localhost:8080/expenses \
     *   -H "Content-Type: application/json"
     * @return
     */
    @GET
    public Set<Expense> list() {
        return expenseService.list();
    }

    /**
     * curl -X POST http://localhost:8080/expenses \
     *   -H "Content-Type: application/json" \
     *   -d '{
     *     "name": "Café en Starbucks",
     *     "paymentMethod": "DEBIT_CARD",
     *     "amount": "5.50"
     *   }'
     *   curl -X POST http://localhost:8080/expenses \
     *   -H "Content-Type: application/json" \
     *   -d '{
     *     "name": "Almuerzo en restaurante",
     *     "paymentMethod": "CREDIT_CARD",
     *     "amount": "25.00"
     *   }'
     *
     *
     * @param expense
     * @return
     */
    @POST
    public Expense create(Expense expense) {
        return expenseService.create(expense);
    }

    /**
     * curl -X DELETE http://localhost:8080/expenses/UUID_DEL_GASTO_A_ELIMINAR \
     *   -H "Content-Type: application/json"
     * @param uuid
     * @return
     */

    @DELETE
    @Path("/{uuid}")
    public Set<Expense> delete(UUID uuid) {
        if (!expenseService.delete(uuid)) {
            throw new WebApplicationException(Response.Status.NOT_FOUND);
        }
        return expenseService.list();
    }

    /**
     * curl -X PUT http://localhost:8080/expenses \
     *   -H "Content-Type: application/json" \
     *   -d '{
     *     "uuid": "UUID_DEL_GASTO_A_ACTUALIZAR",
     *     "name": "Café en Starbucks - Actualizado",
     *     "paymentMethod": "CASH",
     *     "amount": "6.00"
     *   }'
     * @param expense
     */
    @PUT
    public void update(Expense expense) {
        expenseService.update(expense);
    }
}