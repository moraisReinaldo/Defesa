package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.RotaEmergencia;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RotaEmergenciaRepository extends JpaRepository<RotaEmergencia, String> {

    List<RotaEmergencia> findByCidadeIgnoreCaseOrderByDataCriacaoDesc(String cidade);

    List<RotaEmergencia> findByCidadeIgnoreCaseAndAtivaTrueOrderByDataCriacaoDesc(String cidade);

    List<RotaEmergencia> findByAtivaTrueOrderByDataCriacaoDesc();

    @Query("SELECT r FROM RotaEmergencia r WHERE (" +
           ":cidade IS NULL OR " +
           "LOWER(r.cidade) = LOWER(:cidade) OR " +
           "(:codigo IS NOT NULL AND LOWER(r.cidade) = LOWER(:codigo)) OR " +
           "(:nome IS NOT NULL AND LOWER(r.cidade) = LOWER(:nome))" +
           ") ORDER BY r.dataCriacao DESC")
    List<RotaEmergencia> findByCidadeFlexible(
            @Param("cidade") String cidade,
            @Param("codigo") String codigo,
            @Param("nome") String nome);

    @Query("SELECT r FROM RotaEmergencia r WHERE r.ativa = true AND (" +
           ":cidade IS NULL OR " +
           "LOWER(r.cidade) = LOWER(:cidade) OR " +
           "(:codigo IS NOT NULL AND LOWER(r.cidade) = LOWER(:codigo)) OR " +
           "(:nome IS NOT NULL AND LOWER(r.cidade) = LOWER(:nome))" +
           ") ORDER BY r.dataCriacao DESC")
    List<RotaEmergencia> findAtivasByCidadeFlexible(
            @Param("cidade") String cidade,
            @Param("codigo") String codigo,
            @Param("nome") String nome);
}
