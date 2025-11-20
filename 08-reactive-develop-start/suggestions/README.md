
Paso 1:
mvn quarkus:add-extension -Dextensions="hibernate-reactive-panache,reactive-pg-client"

Paso 2:
quarkus.datasource.devservices.image-name=postgres:14.1

Paso 3:  SuggestionResource.java
@POST
public Uni<Suggestion> create(Suggestion newSuggestion) {
return Panache.withTransaction(newSuggestion::persist);
}
Paso 4:
@GET
@Path( "/{id}" )
public Uni<Suggestion> get( Long id ) {
return Suggestion.findById( id );
}
