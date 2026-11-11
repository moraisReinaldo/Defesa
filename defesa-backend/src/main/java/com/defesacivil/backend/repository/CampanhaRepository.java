package com.defesacivil.backend.repository;

import com.defesacivil.backend.domain.CampanhaInstitucional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CampanhaRepository extends JpaRepository<CampanhaInstitucional, String> {
    List<CampanhaInstitucional> findByAtivoTrue();
    List<CampanhaInstitucional> findByCidadeIgnoreCaseAndAtivoTrue(String cidade);
}
