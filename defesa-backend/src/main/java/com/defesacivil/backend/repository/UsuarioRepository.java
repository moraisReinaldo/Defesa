package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.domain.enums.Role;
import com.defesacivil.backend.domain.enums.Status;
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

    @Autowired(required = false)
    private Firestore firestore;

    private static final String COLLECTION_NAME = "usuarios";

    public Usuario save(Usuario usuario) {
        if (firestore == null) throw new RuntimeException("Firestore não configurado.");
        if (usuario.getId() == null) {
            usuario.setId(UUID.randomUUID().toString());
        }
        firestore.collection(COLLECTION_NAME).document(usuario.getId()).set(usuario);
        return usuario;
    }

    public Optional<Usuario> findById(String id) {
        if (firestore == null) return Optional.empty();
        try {
            DocumentSnapshot document = firestore.collection(COLLECTION_NAME).document(id).get().get();
            if (document.exists()) {
                return Optional.of(document.toObject(Usuario.class));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return Optional.empty();
    }

    public Optional<Usuario> findByEmail(String email) {
        if (firestore == null) return Optional.empty();
        try {
            ApiFuture<QuerySnapshot> query = firestore.collection(COLLECTION_NAME)
                    .whereEqualTo("email", email).get();
            List<QueryDocumentSnapshot> documents = query.get().getDocuments();
            if (!documents.isEmpty()) {
                return Optional.of(documents.get(0).toObject(Usuario.class));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return Optional.empty();
    }

    public List<Usuario> findByCidadeAndRole(String cidade, Role role) {
        if (firestore == null) return new ArrayList<>();
        List<Usuario> usuariosEncontrados = new ArrayList<>();
        try {
            ApiFuture<QuerySnapshot> query = firestore.collection(COLLECTION_NAME)
                    .whereEqualTo("cidade", cidade)
                    .whereEqualTo("role", role.name())
                    .get();

            List<QueryDocumentSnapshot> documents = query.get().getDocuments();
            for (DocumentSnapshot doc : documents) {
                usuariosEncontrados.add(doc.toObject(Usuario.class));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return usuariosEncontrados;
    }

    public List<Usuario> findByCidadeIgnoreCaseAndRoleAndStatusIn(String cidade, Role role, List<Status> statuses) {
        if (firestore == null) return new ArrayList<>();
        List<Usuario> usuariosEncontrados = new ArrayList<>();
        try {
            ApiFuture<QuerySnapshot> query = firestore.collection(COLLECTION_NAME)
                    .whereEqualTo("cidade", cidade)
                    .whereEqualTo("role", role.name())
                    .whereIn("status", statuses.stream().map(Status::name).toList())
                    .get();

            List<QueryDocumentSnapshot> documents = query.get().getDocuments();
            for (DocumentSnapshot doc : documents) {
                usuariosEncontrados.add(doc.toObject(Usuario.class));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return usuariosEncontrados;
    }
}
