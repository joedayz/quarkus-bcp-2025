package com.bcp;

import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;

import java.util.Set;
import java.util.UUID;


public class ExpenseResource {


    public ExpenseService expenseService;



    public Set<Expense> list() {
        return expenseService.list();
    }



    public Expense create(Expense expense) {
        return expenseService.create(expense);
    }


    public Set<Expense> delete(UUID uuid) {
        if (!expenseService.delete(uuid)) {
            throw new WebApplicationException(Response.Status.NOT_FOUND);
        }
        return expenseService.list();
    }


    public void update(Expense expense) {
        expenseService.update(expense);
    }
}