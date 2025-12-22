package com.redhat.smartcity;

import io.quarkus.hibernate.orm.panache.PanacheEntity;
import jakarta.persistence.Entity;

@Entity
public class Park extends PanacheEntity {
    public String name;
    public String city;
    public Status status;
    public Integer size;

    public enum Status {
        OPEN, CLOSED
    }
}