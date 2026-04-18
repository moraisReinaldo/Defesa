package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.Ocorrencia;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface OcorrenciaRepository extends JpaRepository<Ocorrencia, String> {
    
    Page<Ocorrencia> findByCidadeIgnoreCaseOrderByDataHoraDesc(String cidade, Pageable pageable);

    @Query("SELECT o FROM Ocorrencia o WHERE " +
           "(LOWER(o.cidade) = LOWER(:cidade) AND o.status <> 'PENDENTE_APROVACAO') " +
           "OR (o.usuarioId = :usuarioId) " +
           "ORDER BY o.dataHora DESC")
    Page<Ocorrencia> findPublicByCidadeOrCreator(
            @Param("cidade") String cidade, 
            @Param("usuarioId") String usuarioId,
            Pageable pageable);
}
