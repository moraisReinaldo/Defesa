package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.Comentario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ComentarioRepository extends JpaRepository<Comentario, String> {
    List<Comentario> findByOcorrenciaIdOrderByDataHoraAsc(String ocorrenciaId);
}
