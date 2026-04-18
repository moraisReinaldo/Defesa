package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.PontoInteresse;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PontoInteresseRepository extends JpaRepository<PontoInteresse, String> {
    List<PontoInteresse> findByCidadeIgnoreCase(String cidade);
}
