package com.bcp.training;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.sql.SQLOutput;

@ApplicationScoped
public class ExpenseValidator {

    boolean debug=true;
    private static final int RANGE_HIGH = 1000;
    private static final int RANGE_LOW = 250;


    public void debugRanges() {
        System.out.println("RANGE HIGH: " + RANGE_HIGH);
        System.out.println("RANGE LOW: " + RANGE_LOW);
    }

    public boolean isValidAmount(int amount) {
        if (debug) {
            debugRanges();
        }
        return amount >= RANGE_LOW && amount <= RANGE_HIGH;
    }
}
