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

    @Query("SELECT o FROM Ocorrencia o LEFT JOIN o.cidadeEntidade c WHERE " +
           "(:cidade IS NULL OR " +
           "LOWER(o.cidade) = LOWER(:cidade) OR " +
           "(:codigo IS NOT NULL AND LOWER(o.cidade) = LOWER(:codigo)) OR " +
           "(:nome IS NOT NULL AND LOWER(o.cidade) = LOWER(:nome)) OR " +
           "(c IS NOT NULL AND (" +
           "  (:codigo IS NOT NULL AND LOWER(c.codigo) = LOWER(:codigo)) OR " +
           "  (:nome IS NOT NULL AND LOWER(c.nome) = LOWER(:nome))" +
           "))) " +
           "ORDER BY o.dataHora DESC")
    Page<Ocorrencia> findByCidadeFlexible(
            @Param("cidade") String cidade,
            @Param("codigo") String codigo,
            @Param("nome") String nome,
            Pageable pageable);

    @Query("SELECT o FROM Ocorrencia o LEFT JOIN o.cidadeEntidade c WHERE " +
           "(:cidade IS NULL OR " +
           "LOWER(o.cidade) = LOWER(:cidade) OR " +
           "(:codigo IS NOT NULL AND LOWER(o.cidade) = LOWER(:codigo)) OR " +
           "(:nome IS NOT NULL AND LOWER(o.cidade) = LOWER(:nome)) OR " +
           "(c IS NOT NULL AND (" +
           "  (:codigo IS NOT NULL AND LOWER(c.codigo) = LOWER(:codigo)) OR " +
           "  (:nome IS NOT NULL AND LOWER(c.nome) = LOWER(:nome))" +
           "))) AND " +
           "((o.status IS NULL OR o.status NOT IN ('PENDENTE_APROVACAO', 'RECUSADA')) " +
           "OR (:usuarioId IS NOT NULL AND o.usuarioId = :usuarioId)) " +
           "ORDER BY o.dataHora DESC")
    Page<Ocorrencia> findPublicByCidadeOrCreatorFlexible(
            @Param("cidade") String cidade,
            @Param("codigo") String codigo,
            @Param("nome") String nome,
            @Param("usuarioId") String usuarioId,
            Pageable pageable);

    @Query("SELECT o FROM Ocorrencia o WHERE " +
           "((o.status IS NULL OR o.status NOT IN ('PENDENTE_APROVACAO', 'RECUSADA')) " +
           "OR (:usuarioId IS NOT NULL AND o.usuarioId = :usuarioId)) " +
           "ORDER BY o.dataHora DESC")
    Page<Ocorrencia> findPublicOcorrencias(
            @Param("usuarioId") String usuarioId,
            Pageable pageable);

    Page<Ocorrencia> findByCidadeIgnoreCaseOrderByDataHoraDesc(String cidade, Pageable pageable);

    /**
     * Busca centroide geográfico de relatos similares próximos via PostGIS.
     * Retorna Object[]{total, lat_media, lng_media} ou null se não houver registros.
     * Raio em metros, janela em horas.
     */
    @Query(value = """
        SELECT
            COUNT(*)::integer AS total,
            AVG(latitude)     AS lat_centro,
            AVG(longitude)    AS lng_centro
        FROM ocorrencias
        WHERE tipo = :tipo
          AND status NOT IN ('RECUSADA', 'RESOLVIDA')
          AND data_hora >= NOW() - (:janela * INTERVAL '1 hour')
          AND ST_DWithin(
              geom::geography,
              ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
              :raio
          )
        """, nativeQuery = true)
    Object[] buscarCentroideProximo(
            @Param("tipo")   String tipo,
            @Param("lat")    double lat,
            @Param("lng")    double lng,
            @Param("raio")   int raioMetros,
            @Param("janela") int janelasHoras
    );
}
