package com.bcp.training.reactive;

import com.bcp.training.event.BankAccountWasCreated;
import com.bcp.training.model.BankAccount;
import org.hibernate.reactive.mutiny.Mutiny;
import org.jboss.logging.Logger;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

@ApplicationScoped
public class AccountTypeProcessor {
    private static final Logger LOGGER = Logger.getLogger(AccountTypeProcessor.class);

    @Inject
    Mutiny.SessionFactory session;

    public String calculateAccountType(Long balance) {
    }

    private void logEvent(BankAccountWasCreated event, String assignedType) {
        LOGGER.infov(
                "Processing BankAccountWasCreated - ID: {0} Balance: {1} Type: {2}",
                event.id,
                event.balance,
                assignedType
        );
    }
}
