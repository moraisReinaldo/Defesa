package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Cidade;
import com.defesacivil.backend.repository.CidadeRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class CidadeService {

    private final CidadeRepository repository;

    public CidadeService(CidadeRepository repository) {
        this.repository = repository;
    }

    public List<Cidade> listarTodas() {
        return repository.findAll();
    }

    public Optional<Cidade> buscarPorId(String id) {
        return repository.findById(id);
    }
    
    public Optional<Cidade> buscarPorNome(String nome) {
        return repository.findByNomeIgnoreCase(nome);
    }

    public Cidade salvar(Cidade cidade) {
        return repository.save(cidade);
    }

    public void deletar(String id) {
        repository.deleteById(id);
    }
}
