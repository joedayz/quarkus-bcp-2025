# AGENTS.md

## Scope and repo shape
- This repository is a Quarkus workshop, not a single deployable system.
- Most labs come in pairs: `*-start/` (exercise baseline) and `*-solution/` (reference implementation).
- Treat each lab subdirectory as an independent project with its own `pom.xml`, wrapper scripts, and `src/` tree.
- Root `README.md` is minimal; real context is inside lab folders and LAB guides.

## Big picture architecture to learn first
- Progression is intentional: config -> REST -> persistence -> native -> testing -> reactive -> security -> resilience -> observability.
- Cross-service REST pattern appears early in `02-develop-rest-solution/expense-client` -> `expense-service`.
- Reactive integration pattern appears in `comprehensive-review-*/parks` consuming `weather` via REST and Kafka.
- Monitoring stack pattern is centralized in `21-monitor-review-solution/docker-compose.yml` (Jaeger, Prometheus, Grafana).

## High-value files to inspect before changing code
- `comprehensive-review-solution/LAB-PROYECTO-FINAL.md` (end-to-end requirements and service boundaries).
- `comprehensive-review-solution/parks/src/main/resources/application.properties` (DB, CORS, REST client, JWT, Kafka wiring).
- `comprehensive-review-solution/parks/src/main/java/com/redhat/smartcity/ParksResource.java` (REST + security + Panache usage).
- `comprehensive-review-solution/parks/src/main/java/com/redhat/smartcity/WeatherWarningsProcessor.java` (Reactive Messaging consumer).
- `02-develop-rest-solution/expense-client/src/main/java/com/bcp/training/client/ExpenseServiceClient.java` (REST client convention).

## Developer workflows that are easy to miss
- Run commands from the specific lab module you are editing (no root Maven reactor build).
- Standard dev loop in module dirs:
  - `./mvnw quarkus:dev`
  - `./mvnw test`
  - `./mvnw package`
- Monitoring lab uses helper script: `21-monitor-review-solution/start-monitoring.sh` (expects `podman compose`).
- Some docs still mention `docker-compose`; confirm container runtime per lab before scripting.

## Guide authoring rules for this repo
- In every LAB/guide markdown, provide command variants for both `bash` (Linux/macOS) and Windows PowerShell when commands are included.
- If a guide includes container commands with Docker, include equivalent Podman commands in the same section.
- Keep command blocks copy-paste ready and labeled by shell/runtime (for example: "Bash", "PowerShell", "Docker", "Podman").
- When only one runtime is verified in that lab, state it explicitly and still provide the closest equivalent command with a brief note.

## Project-specific coding patterns
- JAX-RS resource classes are named `*Resource` and expose JSON endpoints (example: `ExpenseResource`, `ParksResource`).
- REST clients use `@RegisterRestClient(configKey = "...")` + URL in `application.properties` (example key: `weather-api`, `expense-service`).
- Persistence in later labs uses Panache active-record style (`Park.listAll()`, `Park.findById(...)`).
- Async/event code uses Mutiny `Uni` and MicroProfile Reactive Messaging `@Incoming`.
- Security labs use JWT claims/roles directly in code (`JwtGenerator`, `@RolesAllowed("Admin")`).

## Testing conventions in this repo
- Quarkus integration tests use `@QuarkusTest` with RestAssured assertions.
- Typical endpoint test style: `given().when().get(...).then().statusCode(200)`.
- Example references:
  - `comprehensive-review-solution/parks/src/test/java/com/redhat/smartcity/ParksResourceTest.java`
  - `05-demo-test-solution/test-unit/src/test/java/com/bcp/training/expenses/ExpenseCreationTest.java`

## Existing AI-instruction sources
- One glob scan found README-heavy guidance and no strong pre-existing agent rule files at root.
- Keep using this discovery pattern when starting work:
  - `**/{.github/copilot-instructions.md,AGENT.md,AGENTS.md,CLAUDE.md,.cursorrules,.windsurfrules,.clinerules,.cursor/rules/**,.windsurf/rules/**,.clinerules/**,README.md}`

