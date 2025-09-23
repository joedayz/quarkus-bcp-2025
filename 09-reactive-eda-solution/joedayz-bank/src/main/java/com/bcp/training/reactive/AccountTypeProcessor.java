package com.bcp.training.reactive;


import com.bcp.training.event.BankAccountWasCreated;
import com.bcp.training.model.BankAccount;
import io.smallrye.mutiny.Uni;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.context.control.ActivateRequestContext;
import jakarta.inject.Inject;


import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.hibernate.reactive.mutiny.Mutiny;
import org.jboss.logging.Logger;

@ApplicationScoped
public class AccountTypeProcessor {
    private static final Logger LOGGER = Logger.getLogger(AccountTypeProcessor.class);

    @Inject
    Mutiny.SessionFactory session;

    @Incoming("new-bank-accounts-in")
    @ActivateRequestContext
    public Uni<Void> processNewBankAccountEvents(BankAccountWasCreated event){
        String assignedAccountType = calculateAccountType(event.balance);

        logEvent(event,  assignedAccountType);

        return session.withTransaction(
                s -> BankAccount.<BankAccount>findById(event.id)
                        .onItem()
                        .ifNotNull()
                        .invoke(
                                entity -> entity.type = assignedAccountType)
                        .replaceWithVoid()
        );
    }


    public String calculateAccountType(Long balance) {
        return balance >=100000 ? "premium" : "regular";
    }

    private void logEvent(BankAccountWasCreated event, String assignedType) {
        LOGGER.infov(
                "Processing BankAccountWasCreated.java - ID: {0} Balance: {1} Type: {2}",
                event.id,
                event.balance,
                assignedType
        );
    }
}