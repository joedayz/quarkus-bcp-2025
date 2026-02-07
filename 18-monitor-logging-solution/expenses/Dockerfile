####
# Dockerfile para la aplicación Quarkus con logging configurado para Fluentd
#
# Antes de construir la imagen, ejecuta:
# ./mvnw package
#
# Luego, construye la imagen con:
# docker build -t expenses-app .
# o
# podman build -t expenses-app .
###
FROM registry.access.redhat.com/ubi9/openjdk-21:1.23

ENV LANGUAGE='en_US:en'

# Copiar script de entrada
COPY --chown=185 docker-entrypoint.sh /deployments/docker-entrypoint.sh
RUN chmod +x /deployments/docker-entrypoint.sh

# Copiar las capas de la aplicación
COPY --chown=185 target/quarkus-app/lib/ /deployments/lib/
COPY --chown=185 target/quarkus-app/*.jar /deployments/
COPY --chown=185 target/quarkus-app/app/ /deployments/app/
COPY --chown=185 target/quarkus-app/quarkus/ /deployments/quarkus/

EXPOSE 8080
USER 185
ENV JAVA_OPTS_APPEND="-Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager"
ENV JAVA_APP_JAR="/deployments/quarkus-run.jar"

ENTRYPOINT [ "/deployments/docker-entrypoint.sh", "/opt/jboss/container/java/run/run-java.sh" ]

