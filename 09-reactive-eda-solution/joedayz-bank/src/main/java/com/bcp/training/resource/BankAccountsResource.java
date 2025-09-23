package com.bcp.training.resource;

import com.bcp.training.model.BankAccount;
import io.quarkus.hibernate.reactive.panache.Panache;
import io.quarkus.panache.common.Sort;
import io.smallrye.mutiny.Uni;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import java.util.List;

@Path("/accounts")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class BankAccountsResource {
    @GET
    public Uni<List<BankAccount>> get() {
        return BankAccount.listAll(Sort.by("id"));
    }

    @POST
    public Uni<Response> create(BankAccount bankAccount) {
        return Panache
                .<BankAccount>withTransaction(bankAccount::persist)
                .onItem()
                .transform(
                    inserted -> {
                        return Response.created(
                                URI.create("/accounts/" + inserted.id)
                        ).build();
                    }
                );
    }

    public void sendBankAccountEvent(Long id, Long balance) {
    }
}
