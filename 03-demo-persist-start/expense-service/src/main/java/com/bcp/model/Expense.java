package com.bcp.model;

import io.quarkus.hibernate.orm.panache.PanacheEntity;
import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.json.bind.annotation.JsonbCreator;
import jakarta.json.bind.annotation.JsonbDateFormat;
import jakarta.json.bind.annotation.JsonbTransient;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Entity
public class Expense extends PanacheEntity {

    public enum PaymentMethod {
        CASH, CREDIT_CARD, DEBIT_CARD,
    }

    @NotNull
    public UUID uuid;
    public String name;

    @JsonbDateFormat(value = "yyyy-MM-dd HH:mm:ss")
    public LocalDateTime creationDate;
    public PaymentMethod paymentMethod;
    public BigDecimal amount;

    @JsonbTransient
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "associate_id", insertable = false, updatable = false)
    public Associate associate;

    @Column(name = "associate_id")
    public Long associateId;

    public Expense() {
    }

    public Expense(UUID uuid, String name, LocalDateTime creationDate,
                   PaymentMethod paymentMethod, String amount, Associate associate) {
        this.uuid = uuid;
        this.name = name;
        this.creationDate = creationDate;
        this.paymentMethod = paymentMethod;
        this.amount = new BigDecimal(amount);
        this.associate = associate;
        this.associateId = associate.id;
    }

    public Expense(String name, PaymentMethod paymentMethod, String amount, Associate associate) {
        this(UUID.randomUUID(), name, LocalDateTime.now(), paymentMethod, amount, associate);
    }

    @JsonbCreator
    public static Expense of(String name, PaymentMethod paymentMethod, String amount, Long associateId) {

        return Associate.<Associate>findByIdOptional(associateId)
                .map(associate -> new Expense(name, paymentMethod, amount, associate))
                .orElseThrow(RuntimeException::new);
    }

    public static void update(final Expense expense) {
        Optional<Expense> previousExpense = Expense.findByIdOptional(expense.id);

        previousExpense.ifPresentOrElse(updateExpense -> {
            updateExpense.uuid = expense.uuid;
            updateExpense.name = expense.name;
            updateExpense.paymentMethod = expense.paymentMethod;
            updateExpense.amount = expense.amount;
            updateExpense.persist();
        }, () -> {
            throw new WebApplicationException(Response.Status.NOT_FOUND);
        });

    }

}
