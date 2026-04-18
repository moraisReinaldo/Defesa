package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.Ocorrencia;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OcorrenciaRepository extends JpaRepository<Ocorrencia, String> {
    List<Ocorrencia> findByCidadeIgnoreCaseOrderByDataHoraDesc(String cidade);
}
