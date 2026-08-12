package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.Alerta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AlertaRepository extends JpaRepository<Alerta, String> {
    List<Alerta> findByCidadeAndAtivoTrueOrderByDataCriacaoDesc(String cidade);
    List<Alerta> findByAtivoTrueOrderByDataCriacaoDesc();

    @Query("SELECT a FROM Alerta a WHERE a.ativo = true AND (" +
           "LOWER(a.cidade) = LOWER(:cidade) OR " +
           "(LOWER(:cidade) = 'joa' AND LOWER(a.cidade) LIKE '%joan%') OR " +
           "(LOWER(:cidade) = 'pir' AND LOWER(a.cidade) LIKE '%pira%') OR " +
           "(LOWER(:cidade) = 'ati' AND LOWER(a.cidade) LIKE '%atib%') OR " +
           "(LOWER(:cidade) = 'bp' AND LOWER(a.cidade) LIKE '%brag%') OR " +
           "(LOWER(:cidade) = 'naz' AND LOWER(a.cidade) LIKE '%naza%') OR " +
           "(LOWER(:cidade) = 'tui' AND LOWER(a.cidade) LIKE '%tui%') OR " +
           "(LOWER(:cidade) = 'var' AND LOWER(a.cidade) LIKE '%varg%') " +
           ") ORDER BY a.dataCriacao DESC")
    List<Alerta> buscarPorCidadeFlexivel(@Param("cidade") String cidade);
}
