#!/bin/sh

echo "Adding tracing extension to the 'solver' project "
cd solver
mvn quarkus:add-extension -Dextension="opentelemetry"
cd ..

echo "Adding tracing extension to the 'adder' project "
cd adder
mvn quarkus:add-extension -Dextension="opentelemetry"
cd ..

echo "Adding tracing extension to the 'multiplier' project "
cd multiplier
mvn quarkus:add-extension -Dextension="opentelemetry"
cd ..

echo
