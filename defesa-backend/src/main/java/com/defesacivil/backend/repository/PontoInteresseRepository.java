package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.PontoInteresse;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PontoInteresseRepository extends JpaRepository<PontoInteresse, String> {
    @Query("SELECT p FROM PontoInteresse p WHERE LOWER(p.cidade) = LOWER(:cidade) OR p.cidade IS NULL OR p.cidade = ''")
    List<PontoInteresse> findByCidadeIgnoreCase(@Param("cidade") String cidade);

    @Query("SELECT p FROM PontoInteresse p LEFT JOIN p.cidadeEntidade c WHERE " +
           "(:cidade IS NULL OR p.cidade IS NULL OR p.cidade = '' OR " +
           "LOWER(p.cidade) = LOWER(:cidade) OR " +
           "(:codigo IS NOT NULL AND LOWER(p.cidade) = LOWER(:codigo)) OR " +
           "(:nome IS NOT NULL AND LOWER(p.cidade) = LOWER(:nome)) OR " +
           "(c IS NOT NULL AND (" +
           "  (:codigo IS NOT NULL AND LOWER(c.codigo) = LOWER(:codigo)) OR " +
           "  (:nome IS NOT NULL AND LOWER(c.nome) = LOWER(:nome))" +
           ")))")
    List<PontoInteresse> findByCidadeFlexible(
            @Param("cidade") String cidade,
            @Param("codigo") String codigo,
            @Param("nome") String nome);
}
