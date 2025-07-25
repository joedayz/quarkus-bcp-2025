package com.bcp;

import io.quarkus.hibernate.orm.panache.PanacheEntity;
import jakarta.persistence.Entity;

@Entity
public class Talk extends PanacheEntity {
    public String title;
    public int duration;
}
