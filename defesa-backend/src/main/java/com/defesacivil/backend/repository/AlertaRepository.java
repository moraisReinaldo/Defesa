package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.Alerta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AlertaRepository extends JpaRepository<Alerta, String> {
    List<Alerta> findByCidadeIgnoreCaseAndAtivoTrueOrderByDataCriacaoDesc(String cidade);
    List<Alerta> findByAtivoTrueOrderByDataCriacaoDesc();
}

