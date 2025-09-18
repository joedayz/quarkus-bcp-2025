package com.bcp.training.expenses;

import java.math.BigDecimal;

import org.junit.jupiter.api.Test;
import com.bcp.training.expenses.Expense.PaymentMethod;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;


public class ExpenseValidationTest {

    ExpenseConfiguration config;

    ExpenseValidator validator;

    @Test
    public void testExpenseWithMaxAmountIsValid() {
        var expense = givenExpenseWithAmount( config.maxAmount() );

        assertTrue( validator.isValid( expense ) );
    }

    @Test
    public void testExpenseOverMaxAmountIsInvalid() {
        var expense = givenExpenseWithAmount( config.maxAmount().add( new BigDecimal( 0.1 ) ) );

        assertFalse( validator.isValid( expense ) );
    }

    private Expense givenExpenseWithAmount( BigDecimal amount ) {
        return Expense.of( "Max amount expense", PaymentMethod.CREDIT_CARD, amount.toString() );
    }
}
