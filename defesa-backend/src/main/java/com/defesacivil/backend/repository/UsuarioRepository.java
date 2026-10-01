package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, String> {

    Optional<Usuario> findByEmail(String email);

    @Query("SELECT u FROM Usuario u WHERE u.role = :role AND (:cidade IS NULL OR LOWER(u.cidade) = LOWER(:cidade))")
    List<Usuario> findByCidadeAndRole(@Param("cidade") String cidade, @Param("role") String role);

    List<Usuario> findByCidadeIgnoreCaseAndRoleAndStatusIn(String cidade, String role, List<String> statuses);

    List<Usuario> findByStatus(String status);

    long countByCidadeIgnoreCaseAndRole(String cidade, String role);

    List<Usuario> findByCidadeIgnoreCaseAndRole(String cidade, String role);

    List<Usuario> findByCidadeIgnoreCase(String cidade);

    List<Usuario> findByCidadeIgnoreCaseAndStatus(String cidade, String status);

    /** IDs de admins/agentes ativos de uma cidade — usado para push de alerta de IA. */
    @Query("SELECT u.id FROM Usuario u WHERE LOWER(u.cidade) = LOWER(:cidade) " +
           "AND u.role IN ('ADMINISTRADOR', 'AGENTE') AND u.status = 'ATIVO'")
    List<String> findAdminIdsByCidade(@Param("cidade") String cidade);

    List<Usuario> findByCidadeIgnoreCaseAndRoleOrderByDataCriacaoAsc(String cidade, String role);
}
