package com.bcp;

import io.quarkus.test.Mock;

import java.util.UUID;

@Mock
public class ExpenseServiceMock extends ExpenseService {
    public boolean exists(UUID uuid) {
        return !uuid.equals(UUID.fromString(CrudTest.NON_EXISTING_UUID));
    }
}
