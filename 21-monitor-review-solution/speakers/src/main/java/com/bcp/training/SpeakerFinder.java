package com.bcp.training;
import java.util.List;
import java.util.Optional;

import io.opentelemetry.instrumentation.annotations.WithSpan;
import jakarta.enterprise.context.ApplicationScoped;

import io.quarkus.logging.Log;
import io.quarkus.panache.common.Sort;


@ApplicationScoped
public class SpeakerFinder {

    @WithSpan
    public List<Speaker> all() {
        Log.info( "Retrieving all speakers from database" );

        //runSlowAndRedundantOperation();

        return Speaker.listAll();
    }

    public List<Speaker> allSorted( String sortField ) {
        return Speaker.findAll( sortBy( sortField ) ).list();
    }

    private Sort sortBy( String sortField ) {
        return Optional.ofNullable( sortField ).map( Sort::by ).orElse( Sort.by( "nameLast" ) );
    }

    private static void runSlowAndRedundantOperation() {
        // Simulate delay
        try {
            Thread.sleep( 5000 );
        } catch( Exception e ) {
        }
    }
}
