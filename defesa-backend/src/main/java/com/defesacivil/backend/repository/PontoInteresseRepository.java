package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.PontoInteresse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Repository
public class PontoInteresseRepository {

    private static final Logger log = LoggerFactory.getLogger(PontoInteresseRepository.class);

    @Autowired(required = false)
    private Firestore firestore;

    private static final String COLLECTION_NAME = "pontos_interesse";

    public PontoInteresse save(PontoInteresse ponto) {
        if (firestore == null) throw new RuntimeException("Firestore não configurado.");
        if (ponto.getId() == null) {
            ponto.setId(UUID.randomUUID().toString());
        }
        String idParaSalvar = ponto.getId();
        if (idParaSalvar != null) {
            try {
                firestore.collection(COLLECTION_NAME).document(idParaSalvar).set(ponto).get();
            } catch (Exception e) {
                log.error("Erro ao salvar ponto de interesse no Firestore: {}", e.getMessage(), e);
                throw new RuntimeException("Erro ao salvar ponto de interesse", e);
            }
        }
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
            log.error("Erro ao listar pontos de interesse", e);
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
            log.error("Erro ao buscar pontos de interesse por cidade: {}", cidade, e);
        }
        return pontos;
    }

    public void deleteById(String id) {
        if (firestore == null || id == null) return;
        try {
            firestore.collection(COLLECTION_NAME).document(id).delete().get();
        } catch (Exception e) {
            log.error("Erro ao deletar ponto de interesse: {}", id, e);
        }
    }
}
