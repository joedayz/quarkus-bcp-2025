import Keycloak from "keycloak-js";

const url = process.env.REACT_APP_KEYCLOAK_URL || "https://localhost:8888";
const realm = process.env.REACT_APP_KEYCLOAK_REALM || "quarkus";
const clientId = process.env.REACT_APP_CLIENT_ID || "frontend-service";

const keycloak = new Keycloak({
  url,
  realm,
  clientId,
});

console.log("Instantiated the Keycloak object: %o", keycloak);
console.log("Keycloak URL:", url);
console.log("Keycloak Realm:", realm);
console.log("Keycloak Client ID:", clientId);

export default keycloak;
