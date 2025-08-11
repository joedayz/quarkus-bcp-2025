package com.bcp.serde;

import com.bcp.event.SpeakerWasCreated;
import io.quarkus.kafka.client.serialization.ObjectMapperDeserializer;

public class SpeakerWasCreatedDeserializer extends ObjectMapperDeserializer<SpeakerWasCreated> {
    public SpeakerWasCreatedDeserializer() {
        super(SpeakerWasCreated.class);
    }
}
