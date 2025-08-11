package com.bcp.expense;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;

import java.util.List;

@Path( "/admin" )
public class AdminResource {

    @Inject
    ExpensesService expenses;

    @GET
    @Path( "/expenses" )
    //TODO only admin users
    public List<Expense> listAllExpenses() {
        return expenses.list();
    }

}