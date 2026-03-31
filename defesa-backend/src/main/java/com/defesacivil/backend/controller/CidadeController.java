package com.defesacivil.backend.controller;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@RestController
@RequestMapping("/api/cidades")
public class CidadeController {

    @Autowired(required = false)
    private Firestore firestore;

    /**
     * Retorna a lista de cidades suportadas pelo sistema.
     * Tenta buscar do Firestore, com fallback para lista fixa.
     */
    @GetMapping
    public List<CidadeDTO> listarCidades() {
        if (firestore != null) {
            try {
                List<CidadeDTO> cidades = new ArrayList<>();
                ApiFuture<QuerySnapshot> future = firestore.collection("cidades").get();
                List<QueryDocumentSnapshot> documents = future.get().getDocuments();
                
                for (QueryDocumentSnapshot document : documents) {
                    cidades.add(document.toObject(CidadeDTO.class));
                }
                
                if (!cidades.isEmpty()) {
                    return cidades;
                }
            } catch (Exception e) {
                System.err.println("Erro ao buscar cidades do Firestore, usando fallback: " + e.getMessage());
            }
        }

        // Fallback lista fixa (mesma usada no upload)
        return Arrays.asList(
            new CidadeDTO("ATI", "Atibaia"),
            new CidadeDTO("BP", "Bragança Paulista"),
            new CidadeDTO("JOA", "Joanópolis"),
            new CidadeDTO("NAZ", "Nazaré Paulista"),
            new CidadeDTO("PIR", "Piracaia"),
            new CidadeDTO("TUI", "Tuiuti"),
            new CidadeDTO("VAR", "Vargem")
        );
    }

    public static class CidadeDTO {
        private String codigo;
        private String nome;

        // Construtor padrão necessário para o Firestore
        public CidadeDTO() {}

        public CidadeDTO(String codigo, String nome) {
            this.codigo = codigo;
            this.nome = nome;
        }

        public String getCodigo() { return codigo; }
        public void setCodigo(String codigo) { this.codigo = codigo; }
        
        public String getNome() { return nome; }
        public void setNome(String nome) { this.nome = nome; }
    }
}
