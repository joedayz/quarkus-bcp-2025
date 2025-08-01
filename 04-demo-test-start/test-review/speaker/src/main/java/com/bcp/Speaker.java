package com.bcp;

import jakarta.persistence.Entity;
import jakarta.persistence.Transient;

import io.quarkus.hibernate.orm.panache.PanacheEntity;

import java.util.HashMap;
import java.util.Map;

@Entity
public class Speaker extends PanacheEntity {

    public String uuid;

    public String nameFirst;
    public String nameLast;
    public String organization;
    public String biography;
    public String picture;
    public String twitterHandle;

    @Transient
    public Map<String, String> links = new HashMap<>();

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder( this.getClass().getSimpleName() );
        sb.append( "[" );
        sb.append( "<" ).append( id ).append( ">" );
        sb.append( "," );
        sb.append( "nameFirst=" ).append( nameFirst );
        sb.append( "," );
        sb.append( "nameLast=" ).append( nameLast );
        sb.append( "]" );
        return sb.toString();
    }
}