package com.bcp.training.speaker;



import jakarta.ws.rs.*;
import jakarta.ws.rs.core.*;
import java.net.URI;
import java.util.List;
import java.util.ArrayList;

@Path("/speakers")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class SpeakerResource {

    List<Speaker> speakers = new ArrayList<>();

    @GET
    public List<Speaker> getSpeakers() {
        return speakers;
    }

    @POST
    public Response createSpeaker(Speaker newSpeaker, @Context UriInfo uriInfo) {
        speakers.add(newSpeaker);

        return Response.created(generateUriForSpeaker(newSpeaker, uriInfo))
                .header("id", newSpeaker.id)
                .build();
    }

    private URI generateUriForSpeaker(Speaker speaker, UriInfo uriInfo) {
        return uriInfo.getAbsolutePathBuilder().path("/{id}").build(speaker.id);
    }

    private String filterSortBy(String sortBy) {
        if (!sortBy.equals("id") && !sortBy.equals("name")){
            return "id";
        }

        return sortBy;
    }
}
