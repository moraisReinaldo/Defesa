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

    @Query("SELECT u FROM Usuario u WHERE u.role = :role AND (:cidade IS NULL OR u.cidade = :cidade)")
    List<Usuario> findByCidadeAndRole(@Param("cidade") String cidade, @Param("role") String role);

    List<Usuario> findByCidadeIgnoreCaseAndRoleAndStatusIn(String cidade, String role, List<String> statuses);
}
