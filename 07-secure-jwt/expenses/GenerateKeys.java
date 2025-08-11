import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.util.Base64;

public class GenerateKeys {
    
    public static void main(String[] args) {
        System.out.println("Generando claves RSA para JWT usando Java...");
        
        try {
            // Crear directorio si no existe
            String homeDir = System.getProperty("user.home");
            String keyDir = homeDir + "/DO378/secure-jwt";
            Path keyPath = Paths.get(keyDir);
            
            if (!Files.exists(keyPath)) {
                Files.createDirectories(keyPath);
                System.out.println("Directorio creado: " + keyDir);
            }
            
            // Generar par de claves RSA
            KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
            keyPairGenerator.initialize(2048);
            KeyPair keyPair = keyPairGenerator.generateKeyPair();
            
            PrivateKey privateKey = keyPair.getPrivate();
            PublicKey publicKey = keyPair.getPublic();
            
            // Guardar clave privada
            String privateKeyPath = keyDir + "/privateKey.pem";
            savePrivateKey(privateKey, privateKeyPath);
            System.out.println("Clave privada generada: " + privateKeyPath);
            
            // Guardar clave pública
            String publicKeyPath = keyDir + "/publicKey.pem";
            savePublicKey(publicKey, publicKeyPath);
            System.out.println("Clave pública generada: " + publicKeyPath);
            
            // Mostrar información
            System.out.println("\nInformación de las claves generadas:");
            System.out.println("Clave privada: " + privateKeyPath);
            System.out.println("Clave pública: " + publicKeyPath);
            
            File privateFile = new File(privateKeyPath);
            File publicFile = new File(publicKeyPath);
            
            System.out.println("Tamaño clave privada: " + privateFile.length() + " bytes");
            System.out.println("Tamaño clave pública: " + publicFile.length() + " bytes");
            
            // Mostrar las primeras líneas de cada archivo
            System.out.println("\nContenido de la clave privada (primeras líneas):");
            Files.lines(Paths.get(privateKeyPath)).limit(3).forEach(System.out::println);
            
            System.out.println("\nContenido de la clave pública (primeras líneas):");
            Files.lines(Paths.get(publicKeyPath)).limit(3).forEach(System.out::println);
            
            System.out.println("\n¡Claves generadas exitosamente!");
            System.out.println("Ahora puedes ejecutar tu aplicación Quarkus con JWT habilitado.");
            
        } catch (Exception e) {
            System.err.println("Error generando claves: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
    
    private static void savePrivateKey(PrivateKey privateKey, String filePath) throws IOException {
        try (FileWriter writer = new FileWriter(filePath)) {
            writer.write("-----BEGIN PRIVATE KEY-----\n");
            writer.write(Base64.getEncoder().encodeToString(privateKey.getEncoded()));
            writer.write("\n-----END PRIVATE KEY-----\n");
        }
    }
    
    private static void savePublicKey(PublicKey publicKey, String filePath) throws IOException {
        try (FileWriter writer = new FileWriter(filePath)) {
            writer.write("-----BEGIN PUBLIC KEY-----\n");
            writer.write(Base64.getEncoder().encodeToString(publicKey.getEncoded()));
            writer.write("\n-----END PUBLIC KEY-----\n");
        }
    }
}
