package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.Cidade;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CidadeRepository extends JpaRepository<Cidade, String> {
    Optional<Cidade> findByNomeIgnoreCase(String nome);
    Optional<Cidade> findByCodigoIgnoreCase(String codigo);
}
