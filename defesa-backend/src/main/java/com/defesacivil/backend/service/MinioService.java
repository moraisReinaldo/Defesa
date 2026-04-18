package com.defesacivil.backend.service;

import io.minio.GetPresignedObjectUrlArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.http.Method;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;
import java.util.Base64;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Service
public class MinioService {

    private static final Logger log = LoggerFactory.getLogger(MinioService.class);

    private final MinioClient minioClient;

    @Value("${minio.bucket-name}")
    private String bucketName;

    public MinioService(MinioClient minioClient) {
        this.minioClient = minioClient;
    }

    /**
     * Faz upload de uma imagem em Base64 para o MinIO.
     * @param base64Data String no formato "data:image/jpeg;base64,xxxx" ou apenas o base64 puro.
     * @param folder Pasta no bucket onde o arquivo será salvo.
     * @return Nome do objeto no bucket (key) para salvar no banco.
     */
    public String uploadBase64Image(String base64Data, String folder) {
        if (base64Data == null || base64Data.isEmpty()) return null;

        try {
            String pureBase64 = base64Data;
            String extension = "jpg";
            String contentType = "image/jpeg";
            
            if (base64Data.contains(",")) {
                String prefix = base64Data.split(",")[0];
                pureBase64 = base64Data.split(",")[1];
                
                if (prefix.contains("png")) {
                    extension = "png";
                    contentType = "image/png";
                } else if (prefix.contains("webp")) {
                    extension = "webp";
                    contentType = "image/webp";
                }
            }

            byte[] imageBytes = Base64.getDecoder().decode(pureBase64);
            String objectKey = folder + "/" + UUID.randomUUID().toString() + "." + extension;

            minioClient.putObject(
                PutObjectArgs.builder()
                    .bucket(bucketName)
                    .object(objectKey)
                    .stream(new ByteArrayInputStream(imageBytes), imageBytes.length, -1)
                    .contentType(contentType)
                    .build()
            );

            return objectKey;
        } catch (Exception e) {
            log.error("Erro ao fazer upload para o MinIO: {}", e.getMessage(), e);
            return null;
        }
    }

    /**
     * Gera uma URL presigned com validade de 1 hora.
     * @param objectKey A chave do objeto no bucket (ex: ocorrencias/123.jpg)
     * @return URL temporária para acesso
     */
    public String getPresignedUrl(String objectKey) {
        if (objectKey == null || objectKey.isEmpty() || objectKey.startsWith("http")) {
            return objectKey; // Se já for URL (ex: antigas do firebase) ou null, retorna direto
        }
        
        try {
            return minioClient.getPresignedObjectUrl(
                GetPresignedObjectUrlArgs.builder()
                    .method(Method.GET)
                    .bucket(bucketName)
                    .object(objectKey)
                    .expiry(1, TimeUnit.HOURS)
                    .build()
            );
        } catch (Exception e) {
            log.error("Erro ao gerar presigned URL: {}", e.getMessage(), e);
            return null;
        }
    }
}
