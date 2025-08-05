package com.bcp.serde;

import com.bcp.event.BankAccountWasCreated;
import io.quarkus.kafka.client.serialization.ObjectMapperDeserializer;

public class BankAccountWasCreatedDeserializer extends ObjectMapperDeserializer<BankAccountWasCreated> {
    public BankAccountWasCreatedDeserializer() {
        super(BankAccountWasCreated.class);
    }
}
