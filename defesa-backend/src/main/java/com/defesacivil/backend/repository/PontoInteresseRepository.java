package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.PontoInteresse;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Repository
public class PontoInteresseRepository {

    @Autowired(required = false)
    private Firestore firestore;

    private static final String COLLECTION_NAME = "pontos_interesse";

    public PontoInteresse save(PontoInteresse ponto) {
        if (firestore == null) throw new RuntimeException("Firestore não configurado.");
        if (ponto.getId() == null) {
            ponto.setId(UUID.randomUUID().toString());
        }
        firestore.collection(COLLECTION_NAME).document(ponto.getId()).set(ponto);
        return ponto;
    }

    public List<PontoInteresse> findAll() {
        if (firestore == null) return new ArrayList<>();
        List<PontoInteresse> pontos = new ArrayList<>();
        try {
            ApiFuture<QuerySnapshot> query = firestore.collection(COLLECTION_NAME).get();
            for (DocumentSnapshot doc : query.get().getDocuments()) {
                pontos.add(doc.toObject(PontoInteresse.class));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return pontos;
    }

    public List<PontoInteresse> findByCidadeIgnoreCase(String cidade) {
        if (firestore == null) return new ArrayList<>();
        List<PontoInteresse> pontos = new ArrayList<>();
        try {
            ApiFuture<QuerySnapshot> query = firestore.collection(COLLECTION_NAME)
                    .whereEqualTo("cidade", cidade)
                    .get();
            for (DocumentSnapshot doc : query.get().getDocuments()) {
                pontos.add(doc.toObject(PontoInteresse.class));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return pontos;
    }

    public void deleteById(String id) {
        if (firestore == null) return;
        firestore.collection(COLLECTION_NAME).document(id).delete();
    }
}
