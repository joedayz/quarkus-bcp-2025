package com.redhat.smartcity;

import java.util.List;
import java.util.concurrent.CompletionStage;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.fasterxml.jackson.databind.DeserializationFeature;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.eclipse.microprofile.reactive.messaging.Message;
import com.redhat.smartcity.weather.WeatherWarning;
import io.quarkus.logging.Log;

@jakarta.enterprise.context.ApplicationScoped
public class WeatherWarningsProcessor {

    @Inject
    ParkGuard guard;

    @Channel("parks-under-warning")
    Emitter<List<Park>> emitter;

    private final ObjectMapper objectMapper;

    public WeatherWarningsProcessor() {
        this.objectMapper = new ObjectMapper();
        this.objectMapper.registerModule(new JavaTimeModule());
        this.objectMapper.disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);
    }

    @Incoming("weather-warnings")
    @Transactional
    public CompletionStage<Void> processWeatherWarning(Message<String> message) {
        try {
            String jsonString = message.getPayload();
            Log.info("[EVENT Received JSON] " + jsonString);
            
            WeatherWarning warning = objectMapper.readValue(jsonString, WeatherWarning.class);
            Log.info("[EVENT Received] " + warning);

            List<Park> parks = Park.find("city = ?1", warning.city).list();

            parks.forEach(park -> {
                guard.updateParkBasedOnWarning(park, warning);
            });

            return message.ack();
        } catch (Exception e) {
            Log.error("Error processing weather warning message: " + e.getMessage(), e);
            return message.nack(e);
        }
    }
}
