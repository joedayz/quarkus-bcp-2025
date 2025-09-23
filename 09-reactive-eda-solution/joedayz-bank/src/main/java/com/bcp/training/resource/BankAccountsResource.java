package com.bcp.training.resource;

import com.bcp.training.event.BankAccountWasCreated;
import com.bcp.training.model.BankAccount;
import io.quarkus.hibernate.reactive.panache.Panache;
import io.quarkus.panache.common.Sort;
import io.smallrye.mutiny.Uni;
import jakarta.validation.Valid;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;

import java.net.URI;
import java.util.List;


@Path("/accounts")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class BankAccountsResource {

    @Channel("new-bank-accounts-out")
    Emitter<BankAccountWasCreated> emitter;

    @GET
    public Uni<List<BankAccount>> get() {
        return BankAccount.listAll(Sort.by("id"));
    }

    @POST
    public Uni<Response> create(@Valid BankAccount bankAccount) {
        // Validar que el balance no sea null
        if (bankAccount.balance == null) {
            return Uni.createFrom().item(
                Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"error\": \"El balance no puede ser null\"}")
                    .build()
            );
        }

        // Validar que el balance sea positivo
        if (bankAccount.balance <= 0) {
            return Uni.createFrom().item(
                Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"error\": \"El balance debe ser un número positivo\"}")
                    .build()
            );
        }

        return Panache
                .<BankAccount>withTransaction(bankAccount::persist)
                .onItem()
                .transform(
                        inserted -> {
                            sendBankAccountEvent(inserted.id, inserted.balance);
                            return Response.created(
                                    URI.create("/accounts/" + inserted.id)
                            ).build();
                        }
                );
    }

    public void sendBankAccountEvent(Long id, Long balance) {
        emitter.send(new BankAccountWasCreated(id, balance));
    }
}
