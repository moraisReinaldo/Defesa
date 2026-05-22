package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.PontoInteresse;
import com.defesacivil.backend.repository.PontoInteresseRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class PontoInteresseService {

    private final PontoInteresseRepository repository;

    public PontoInteresseService(PontoInteresseRepository repository) {
        this.repository = repository;
    }

    public List<PontoInteresse> listarTodos() {
        return repository.findAll();
    }

    public List<PontoInteresse> listarPorCidade(String cidade) {
        if (cidade == null || cidade.isBlank()) {
            return listarTodos();
        }
        return repository.findByCidadeIgnoreCase(cidade);
    }

    public PontoInteresse salvar(PontoInteresse ponto) {
        return repository.save(ponto);
    }

    public PontoInteresse atualizar(String id, PontoInteresse dados) {
        PontoInteresse existente = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Ponto de Interesse não encontrado: " + id));
        existente.setTipo(dados.getTipo());
        existente.setDescricao(dados.getDescricao());
        existente.setLatitude(dados.getLatitude());
        existente.setLongitude(dados.getLongitude());
        if (dados.getCidade() != null) existente.setCidade(dados.getCidade());
        return repository.save(existente);
    }

    public void deletar(String id) {
        repository.deleteById(id);
    }
}
