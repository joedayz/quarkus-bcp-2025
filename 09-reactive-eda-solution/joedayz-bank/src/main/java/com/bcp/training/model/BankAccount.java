package com.bcp.training.model;




import io.quarkus.hibernate.reactive.panache.PanacheEntity;


import jakarta.persistence.Cacheable;
import jakarta.persistence.Entity;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

@Entity
@Cacheable
public class BankAccount extends PanacheEntity {

    @NotNull(message = "El balance no puede ser null")
    @Positive(message = "El balance debe ser un número positivo")
    public Long balance;

    public String type;

    public BankAccount() {
    }

    public BankAccount(Long balance, String type) {
        this.balance = balance;
        this.type = type;
    }
}

