package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.Ocorrencia;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.lang.NonNull;
import java.util.Optional;
import java.util.Objects;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Repository
public class OcorrenciaRepository {

    private static final Logger log = LoggerFactory.getLogger(OcorrenciaRepository.class);

    @Autowired(required = false)
    private Firestore firestore;

    private static final String COLLECTION_NAME = "ocorrencias";

    @NonNull
    public Ocorrencia save(Ocorrencia ocorrencia) {
        if (firestore == null) throw new RuntimeException("Firestore não configurado.");
        if (ocorrencia.getId() == null) {
            ocorrencia.setId(UUID.randomUUID().toString());
        }
        try {
            @SuppressWarnings("null")
            String docId = Objects.requireNonNull(ocorrencia.getId());
            firestore.collection(COLLECTION_NAME)
                .document(docId)
                .set(ocorrencia)
                .get(); // Aguardar confirmação da escrita
        } catch (Exception e) {
            log.error("Erro ao salvar ocorrência no Firestore: {}", e.getMessage(), e);
            throw new RuntimeException("Erro ao salvar ocorrência", e);
        }
        return ocorrencia;
    }

    @NonNull
    public Optional<Ocorrencia> findById(@NonNull String id) {
        if (firestore == null) return Optional.empty();
        try {
            @SuppressWarnings("null")
            String docId = Objects.requireNonNull(id);
            DocumentSnapshot doc = firestore.collection(COLLECTION_NAME).document(docId).get().get();
            if (doc.exists()) {
                Ocorrencia o = doc.toObject(Ocorrencia.class);
                return Optional.ofNullable(o);
            }
        } catch (Exception e) {
            log.error("Erro ao buscar ocorrência por ID: {}", id, e);
        }
        return Optional.empty();
    }

    public List<Ocorrencia> findAll() {
        if (firestore == null) return new ArrayList<>();
        List<Ocorrencia> ocorrencias = new ArrayList<>();
        try {
            ApiFuture<QuerySnapshot> query = firestore.collection(COLLECTION_NAME).get();
            for (DocumentSnapshot doc : query.get().getDocuments()) {
                ocorrencias.add(doc.toObject(Ocorrencia.class));
            }
        } catch (Exception e) {
            log.error("Erro ao listar todas as ocorrências", e);
        }
        return ocorrencias;
    }

    public void delete(Ocorrencia ocorrencia) {
        if (firestore != null && ocorrencia.getId() != null) {
            try {
                @SuppressWarnings("null")
                String docId = Objects.requireNonNull(ocorrencia.getId());
                firestore.collection(COLLECTION_NAME).document(docId).delete().get();
            } catch (Exception e) {
                log.error("Erro ao deletar ocorrência: {}", ocorrencia.getId(), e);
            }
        }
    }

    public void deleteById(@NonNull String id) {
        if (firestore != null) {
            try {
                @SuppressWarnings("null")
                String docId = Objects.requireNonNull(id);
                firestore.collection(COLLECTION_NAME).document(docId).delete().get();
            } catch (Exception e) {
                log.error("Erro ao deletar ocorrência por ID: {}", id, e);
            }
        }
    }

    public List<Ocorrencia> findByCidadeIgnoreCaseOrderByDataHoraDesc(String cidade) {
        if (firestore == null) return new ArrayList<>();
        List<Ocorrencia> ocorrencias = new ArrayList<>();
        try {
            ApiFuture<QuerySnapshot> query = firestore.collection(COLLECTION_NAME)
                    .whereEqualTo("cidade", cidade)
                    .get();
            for (DocumentSnapshot doc : query.get().getDocuments()) {
                ocorrencias.add(doc.toObject(Ocorrencia.class));
            }
            // Sort manual na memória para evitar necessidade de índices compostos imediatos no Firebase
            ocorrencias.sort((o1, o2) -> {
                if (o1.getDataHora() == null || o2.getDataHora() == null) return 0;
                return o2.getDataHora().compareTo(o1.getDataHora());
            });
        } catch (Exception e) {
            log.error("Erro ao buscar ocorrências por cidade: {}", cidade, e);
        }
        return ocorrencias;
    }
}
