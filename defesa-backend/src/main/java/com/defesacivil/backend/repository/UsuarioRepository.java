package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.Usuario;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.lang.NonNull;
import java.util.Objects;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class UsuarioRepository {

    private static final Logger log = LoggerFactory.getLogger(UsuarioRepository.class);

    @Autowired(required = false)
    private Firestore firestore;

    private static final String COLLECTION_NAME = "usuarios";

    @NonNull
    public Usuario save(Usuario usuario) {
        if (firestore == null) throw new RuntimeException("Firestore não configurado.");
        if (usuario.getId() == null) {
            usuario.setId(UUID.randomUUID().toString());
        }
        try {
            @SuppressWarnings("null")
            String docId = Objects.requireNonNull(usuario.getId());
            firestore.collection(COLLECTION_NAME).document(docId).set(usuario).get();
        } catch (Exception e) {
            log.error("Erro ao salvar usuário no Firestore: {}", e.getMessage(), e);
            throw new RuntimeException("Erro ao salvar usuário", e);
        }
        return usuario;
    }

    @NonNull
    public Optional<Usuario> findById(@NonNull String id) {
        if (firestore == null) return Optional.empty();
        try {
            @SuppressWarnings("null")
            String docId = Objects.requireNonNull(id);
            DocumentSnapshot document = firestore.collection(COLLECTION_NAME).document(docId).get().get();
            if (document.exists()) {
                return Optional.ofNullable(document.toObject(Usuario.class));
            }
        } catch (Exception e) {
            log.error("Erro ao buscar usuário por ID: {}", id, e);
        }
        return Optional.empty();
    }

    @NonNull
    public Optional<Usuario> findByEmail(@NonNull String email) {
        if (firestore == null) return Optional.empty();
        try {
            ApiFuture<QuerySnapshot> query = firestore.collection(COLLECTION_NAME)
                    .whereEqualTo("email", email).get();
            List<QueryDocumentSnapshot> documents = query.get().getDocuments();
            if (!documents.isEmpty()) {
                Usuario u = documents.get(0).toObject(Usuario.class);
                return Optional.ofNullable(u);
            }
        } catch (Exception e) {
            log.error("Erro ao buscar usuário por email: {}", email, e);
        }
        return Optional.empty();
    }

    public List<Usuario> findByCidadeAndRole(String cidade, String role) {
        if (firestore == null) return new ArrayList<>();
        List<Usuario> usuariosEncontrados = new ArrayList<>();
        try {
            Query query = firestore.collection(COLLECTION_NAME).whereEqualTo("role", role);
            
            if (cidade != null && !cidade.isBlank()) {
                query = query.whereEqualTo("cidade", cidade);
            }

            ApiFuture<QuerySnapshot> apiFuture = query.get();
            List<QueryDocumentSnapshot> documents = apiFuture.get().getDocuments();
            for (DocumentSnapshot doc : documents) {
                usuariosEncontrados.add(doc.toObject(Usuario.class));
            }
        } catch (Exception e) {
            log.error("Erro ao buscar usuários por cidade e role: cidade={}, role={}", cidade, role, e);
        }
        return usuariosEncontrados;
    }

    public List<Usuario> findByCidadeIgnoreCaseAndRoleAndStatusIn(String cidade, String role, List<String> statuses) {
        if (firestore == null) return new ArrayList<>();
        List<Usuario> usuariosEncontrados = new ArrayList<>();
        try {
            ApiFuture<QuerySnapshot> query = firestore.collection(COLLECTION_NAME)
                    .whereEqualTo("cidade", cidade)
                    .whereEqualTo("role", role)
                    .whereIn("status", new ArrayList<>(statuses))
                    .get();

            List<QueryDocumentSnapshot> documents = query.get().getDocuments();
            for (DocumentSnapshot doc : documents) {
                usuariosEncontrados.add(doc.toObject(Usuario.class));
            }
        } catch (Exception e) {
            log.error("Erro ao buscar usuários por cidade, role e status", e);
        }
        return usuariosEncontrados;
    }

    public void deleteById(@NonNull String id) {
        if (firestore != null) {
            try {
                @SuppressWarnings("null")
                String docId = Objects.requireNonNull(id);
                firestore.collection(COLLECTION_NAME).document(docId).delete().get();
            } catch (Exception e) {
                log.error("Erro ao deletar usuário por ID: {}", id, e);
            }
        }
    }
}
