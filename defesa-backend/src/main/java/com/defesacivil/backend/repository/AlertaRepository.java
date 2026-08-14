package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.Alerta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AlertaRepository extends JpaRepository<Alerta, String> {
    @Query("SELECT a FROM Alerta a WHERE a.ativo = true AND (" +
           "(:cidade IS NULL OR " +
           "LOWER(a.cidade) = LOWER(:cidade) OR " +
           "(:codigo IS NOT NULL AND LOWER(a.cidade) = LOWER(:codigo)) OR " +
           "(:nome IS NOT NULL AND LOWER(a.cidade) = LOWER(:nome))" +
           ")) ORDER BY a.dataCriacao DESC")
    List<Alerta> findByCidadeFlexible(
            @Param("cidade") String cidade,
            @Param("codigo") String codigo,
            @Param("nome") String nome);
}

