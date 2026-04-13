package com.defesacivil.backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.storage.Bucket;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.cloud.FirestoreClient;
import com.google.firebase.cloud.StorageClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import jakarta.annotation.PostConstruct;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import org.springframework.util.ResourceUtils;

@Configuration
public class FirebaseConfig {

    private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);

    @Value("${firebase.config.path}")
    private String firebaseConfigPath;

    @Value("${firebase.storage.bucket}")
    private String storageBucket;

    @PostConstruct
    public void initialize() {
        try {
            InputStream serviceAccount;
            
            if (firebaseConfigPath.startsWith("classpath:")) {
                serviceAccount = getClass().getClassLoader().getResourceAsStream(firebaseConfigPath.replace("classpath:", ""));
            } else {
                serviceAccount = new FileInputStream(ResourceUtils.getFile(firebaseConfigPath));
            }

            if (serviceAccount == null) {
                log.warn("Arquivo de configuração do Firebase não encontrado! Para conectar, coloque o serviceAccountKey.json");
                return;
            }

            // Variável final para uso no try-with-resources
            final InputStream stream = serviceAccount;
            try (stream) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(stream))
                        .setStorageBucket(storageBucket)
                        .build();

                if (FirebaseApp.getApps().isEmpty()) {
                    FirebaseApp.initializeApp(options);
                    log.info("Firebase Application inicializada com sucesso!");
                }
            }
        } catch (FileNotFoundException e) {
            log.warn("Arquivo json do Firebase não encontrado no caminho: {}", firebaseConfigPath);
        } catch (Exception e) {
            log.error("Erro ao inicializar Firebase", e);
        }
    }

    @Bean
    public Firestore firestore() {
        if (FirebaseApp.getApps().isEmpty()) return null;
        return FirestoreClient.getFirestore();
    }

    @Bean
    public Bucket storageBucket() {
        if (FirebaseApp.getApps().isEmpty()) return null;
        try {
            return StorageClient.getInstance().bucket();
        } catch (Exception e) {
            log.warn("Não foi possível inicializar o Bucket do Firebase Storage. Upload de fotos desativado. Erro: {}", e.getMessage());
            return null;
        }
    }
}
