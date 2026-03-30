package com.defesacivil.backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.storage.Bucket;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.cloud.FirestoreClient;
import com.google.firebase.cloud.StorageClient;
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

    @Value("${firebase.config.path}")
    private String firebaseConfigPath;

    @Value("${firebase.storage.bucket}")
    private String storageBucket;

    @PostConstruct
    public void initialize() {
        try {
            InputStream serviceAccount = null;
            
            if (firebaseConfigPath.startsWith("classpath:")) {
                serviceAccount = getClass().getClassLoader().getResourceAsStream(firebaseConfigPath.replace("classpath:", ""));
            } else {
                serviceAccount = new FileInputStream(ResourceUtils.getFile(firebaseConfigPath));
            }

            if (serviceAccount == null) {
                System.err.println("ALERTA: Arquivo de configuração do Firebase não encontrado! Para conectar, coloque o serviceAccountKey.json");
                return;
            }

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .setStorageBucket(storageBucket)
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                System.out.println("Firebase Application inicializada com sucesso!");
            }
        } catch (FileNotFoundException e) {
            System.err.println("ALERTA: Arquivo json do Firebase não encontrado no caminho: " + firebaseConfigPath);
        } catch (Exception e) {
            e.printStackTrace();
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
        return StorageClient.getInstance().bucket();
    }
}
