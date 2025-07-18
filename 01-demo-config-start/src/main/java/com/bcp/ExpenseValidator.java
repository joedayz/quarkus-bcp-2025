package com.bcp;

import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.Optional;

@ApplicationScoped
public class ExpenseValidator {

    @ConfigProperty(name = "expense.debug.enabled", defaultValue = "false")
    boolean debugEnabled;

    @ConfigProperty(name = "expense.debug.message")
    Optional<String> debugMessage;

    @ConfigProperty(name = "expense.range-high")
    int rangeHigh;

    @ConfigProperty(name = "expense.range-low")
    int rangeLow;

    public void debugRanges() {
        System.out.println("Range - High: " + rangeHigh);
        System.out.println("Range - Low: " + rangeLow);
    }

    public boolean isValidAmount(int amount) {
        if (debugEnabled) {
            debugRanges();
        }

        return amount >= rangeLow && amount <= rangeHigh;
    }
}
