package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.Ocorrencia;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Repository
public class OcorrenciaRepository {

    @Autowired(required = false)
    private Firestore firestore;

    private static final String COLLECTION_NAME = "ocorrencias";

    public Ocorrencia save(Ocorrencia ocorrencia) {
        if (firestore == null) throw new RuntimeException("Firestore não configurado.");
        if (ocorrencia.getId() == null) {
            ocorrencia.setId(UUID.randomUUID().toString());
        }
        firestore.collection(COLLECTION_NAME).document(ocorrencia.getId()).set(ocorrencia);
        return ocorrencia;
    }

    public Ocorrencia findById(String id) {
        if (firestore == null) return null;
        try {
            DocumentSnapshot doc = firestore.collection(COLLECTION_NAME).document(id).get().get();
            if (doc.exists()) {
                return doc.toObject(Ocorrencia.class);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
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
            e.printStackTrace();
        }
        return ocorrencias;
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
            ocorrencias.sort((o1, o2) -> o2.getDataHora().compareTo(o1.getDataHora()));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return ocorrencias;
    }
}
