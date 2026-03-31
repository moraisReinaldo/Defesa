package com.defesacivil.backend.service;

import com.google.cloud.storage.Bucket;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Base64;
import java.util.UUID;

@Service
public class FirebaseStorageService {

    @Autowired
    private Bucket storageBucket;

    /**
     * Faz upload de uma imagem em Base64 para o Firebase Storage.
     * @param base64Data String no formato "data:image/jpeg;base64,xxxx" ou apenas o base64 puro.
     * @param folder Pasta no bucket onde o arquivo será salvo.
     * @return URL pública do arquivo enviado.
     */
    public String uploadBase64Image(String base64Data, String folder) {
        if (base64Data == null || base64Data.isEmpty()) return null;

        try {
            // Remover prefixo do data URI se existir
            String pureBase64 = base64Data;
            String extension = "jpg";
            if (base64Data.contains(",")) {
                String prefix = base64Data.split(",")[0];
                pureBase64 = base64Data.split(",")[1];
                
                if (prefix.contains("png")) extension = "png";
                else if (prefix.contains("webp")) extension = "webp";
            }

            byte[] imageBytes = Base64.getDecoder().decode(pureBase64);
            String fileName = folder + "/" + UUID.randomUUID().toString() + "." + extension;

            // Fazer upload (o Firebase Admin SDK usa o Bucket do Google Cloud)
            storageBucket.create(fileName, imageBytes, "image/" + extension);

            // Em buckets do Firebase, o formato da URL pública costuma ser:
            // https://firebasestorage.googleapis.com/v0/b/[BUCKET]/o/[NOME_ARQUIVO]?alt=media
            // Nota: O nome do arquivo na URL deve estar URL-encoded (a barra '/' vira '%2F')
            String encodedFileName = fileName.replace("/", "%2F");
            String bucketName = storageBucket.getName();
            
            return String.format("https://firebasestorage.googleapis.com/v0/b/%s/o/%s?alt=media", 
                bucketName, encodedFileName);

        } catch (Exception e) {
            System.err.println("Erro ao fazer upload para o Firebase Storage: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }
}
