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

    /**
     * Retorna ocorrências visíveis para cidadãos:
     * - Ocorrências APROVADAS na cidade informada (visíveis publicamente)
     * - OU qualquer ocorrência criada pelo próprio usuário (mesmo pendente, para ele acompanhar)
     *
     * CORREÇÃO: Usa (:usuarioId IS NULL OR o.usuarioId = :usuarioId) para tratar
     * o caso onde o usuário não está autenticado sem gerar "WHERE usuarioId = null" inválido.
     * Também filtra por cidade para as ocorrências do criador, evitando expor dados cross-city.
     */
    @Query("SELECT o FROM Ocorrencia o WHERE " +
           "(LOWER(o.cidade) = LOWER(:cidade) AND (o.status IS NULL OR o.status NOT IN ('PENDENTE_APROVACAO'))) " +
           "OR (:usuarioId IS NOT NULL AND o.usuarioId = :usuarioId AND LOWER(o.cidade) = LOWER(:cidade)) " +
           "ORDER BY o.dataHora DESC")
    Page<Ocorrencia> findPublicByCidadeOrCreator(
            @Param("cidade") String cidade,
            @Param("usuarioId") String usuarioId,
            Pageable pageable);
}
