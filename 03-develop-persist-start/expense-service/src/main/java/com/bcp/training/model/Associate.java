package com.bcp.training.model;

import java.util.List;
import java.util.ArrayList;

import jakarta.json.bind.annotation.JsonbCreator;


// TODO: Add @Entity annotation and extend PanacheEntity
public class Associate {
    public String name;

    // TODO: Add one to many relationship between associate and expenses
    public List<Expense> expenses = new ArrayList<>();

    // TODO: Add a no-argument constructor

    public Associate(String name) {
        this.name = name;
    }

    @JsonbCreator
    public static Associate of(String name) {
        return new Associate(name);
    }
}
