package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.AlertaClima;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AlertaClimaRepository extends JpaRepository<AlertaClima, String> {

    @Query("SELECT a FROM AlertaClima a WHERE LOWER(a.cidade) = LOWER(:cidade) AND a.dataExpiracao > :agora ORDER BY a.dataCriacao DESC")
    List<AlertaClima> findAlertasAtivosPorCidade(String cidade, LocalDateTime agora);
}
