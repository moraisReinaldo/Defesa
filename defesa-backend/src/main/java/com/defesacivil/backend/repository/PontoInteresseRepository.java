package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.PontoInteresse;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PontoInteresseRepository extends JpaRepository<PontoInteresse, String> {
    @org.springframework.data.jpa.repository.Query("SELECT p FROM PontoInteresse p WHERE LOWER(p.cidade) = LOWER(:cidade) OR p.cidade IS NULL OR p.cidade = ''")
    List<PontoInteresse> findByCidadeIgnoreCase(@org.springframework.data.repository.query.Param("cidade") String cidade);
}
