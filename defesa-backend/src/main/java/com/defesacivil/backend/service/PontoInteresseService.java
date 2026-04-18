package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.PontoInteresse;
import com.defesacivil.backend.repository.PontoInteresseRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class PontoInteresseService {

    @Autowired
    private PontoInteresseRepository repository;

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

    public void deletar(String id) {
        repository.deleteById(id);
    }
}
