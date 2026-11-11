package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.CampanhaInstitucional;
import com.defesacivil.backend.repository.CampanhaRepository;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/campanhas")
public class CampanhaController {

    private static final Logger log = LoggerFactory.getLogger(CampanhaController.class);
    private final CampanhaRepository repository;

    public CampanhaController(CampanhaRepository repository) {
        this.repository = repository;
    }

    @PostConstruct
    public void inicializarCampanhasPadrao() {
        if (repository.count() == 0) {
            log.info("📢 [Campanhas] Inicializando campanhas institucionais padrão...");
            CampanhaInstitucional c1 = new CampanhaInstitucional(
                "Mutirão Contra a Dengue 2026",
                "Descarte entulhos e evite água parada. Agentes municipais de saúde e Defesa Civil nos bairros neste sábado.",
                "Prefeitura Municipal & Defesa Civil",
                "Joanópolis",
                "DENGUE",
                "health_and_safety"
            );
            c1.setLinkExterno("https://defesacivil.sp.gov.br");

            CampanhaInstitucional c2 = new CampanhaInstitucional(
                "Alerta Preventivo de Chuvas de Verão",
                "Em caso de vendaval ou tempestade, conheça a Cartilha R.O.T.A. e os pontos de abrigo no mapa.",
                "Defesa Civil Regional",
                "Joanópolis",
                "CHUVA_FORTE",
                "cloud_queue"
            );
            c2.setLinkExterno("https://spalerta.sp.gov.br");

            CampanhaInstitucional c3 = new CampanhaInstitucional(
                "Campanha de Vacinação e Abrigos de Apoio",
                "Postos de saúde abertos para atualização da caderneta e cadastro de famílias em áreas de encosta.",
                "Secretaria de Saúde",
                "Joanópolis",
                "VACINACAO",
                "medical_services"
            );

            repository.saveAll(List.of(c1, c2, c3));
        }
    }

    @GetMapping
    public ResponseEntity<List<CampanhaInstitucional>> listar(@RequestParam(required = false) String cidade) {
        if (cidade != null && !cidade.isBlank()) {
            List<CampanhaInstitucional> daCidade = repository.findByCidadeIgnoreCaseAndAtivoTrue(cidade);
            if (!daCidade.isEmpty()) {
                return ResponseEntity.ok(daCidade);
            }
        }
        return ResponseEntity.ok(repository.findByAtivoTrue());
    }

    @PostMapping
    public ResponseEntity<CampanhaInstitucional> criar(@RequestBody CampanhaInstitucional campanha) {
        return ResponseEntity.ok(repository.save(campanha));
    }
}
