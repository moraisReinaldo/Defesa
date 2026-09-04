package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.Cidade;
import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.domain.enums.PlanoCidade;
import com.defesacivil.backend.domain.enums.Status;
import com.defesacivil.backend.domain.enums.StatusCidade;
import com.defesacivil.backend.repository.UsuarioRepository;
import com.defesacivil.backend.service.CidadeService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/super")
@PreAuthorize("hasRole('SUPER_ADMIN')")
public class SuperAdminController {

    private final CidadeService cidadeService;
    private final UsuarioRepository usuarioRepository;

    public SuperAdminController(CidadeService cidadeService, UsuarioRepository usuarioRepository) {
        this.cidadeService = cidadeService;
        this.usuarioRepository = usuarioRepository;
    }

    /**
     * Lista todas as cidades pendentes de aprovação pelo Super Admin.
     */
    @GetMapping("/cidades/pendentes")
    public ResponseEntity<List<Map<String, Object>>> listarCidadesPendentes() {
        List<Cidade> pendentes = cidadeService.listarPendentes();
        List<Map<String, Object>> resultado = new ArrayList<>();

        for (Cidade c : pendentes) {
            Map<String, Object> item = new HashMap<>();
            item.put("cidade", c);
            
            // Buscar coordenadores vinculados à cidade
            List<Usuario> gestores = usuarioRepository.findByCidadeIgnoreCaseAndRole(c.getCodigo(), "ADMINISTRADOR");
            item.put("gestores", gestores);
            item.put("totalGestores", gestores.size());
            
            resultado.add(item);
        }

        return ResponseEntity.ok(resultado);
    }

    /**
     * Lista todas as cidades com dados consolidados de licenciamento, gestores e agentes.
     */
    @GetMapping("/cidades")
    public ResponseEntity<List<Map<String, Object>>> listarTodasCidades() {
        List<Cidade> todas = cidadeService.listarTodas();
        List<Map<String, Object>> resultado = new ArrayList<>();

        for (Cidade c : todas) {
            Map<String, Object> item = new HashMap<>();
            item.put("cidade", c);
            
            long totalGestores = usuarioRepository.countByCidadeIgnoreCaseAndRole(c.getCodigo(), "ADMINISTRADOR");
            long totalAgentes = usuarioRepository.countByCidadeIgnoreCaseAndRole(c.getCodigo(), "AGENTE");
            
            item.put("totalGestores", totalGestores);
            item.put("totalAgentes", totalAgentes);
            item.put("trialAtivo", c.isTrialAtivo());
            item.put("diasRestantesTrial", c.getDiasRestantesTrial());
            item.put("planoEfetivo", c.getPlanoEfetivo());
            
            resultado.add(item);
        }

        return ResponseEntity.ok(resultado);
    }

    /**
     * Retorna a minuta/cláusula oficial de adesão do Trial de 120 dias formatada para esta cidade.
     */
    @GetMapping("/cidades/{id}/clausula-trial")
    public ResponseEntity<Map<String, String>> obterClausulaTrial(@PathVariable String id) {
        Cidade cidade = cidadeService.buscarPorId(id)
            .orElseThrow(() -> new IllegalArgumentException("Cidade não encontrada com ID: " + id));

        String clausula = cidadeService.obterClausulaTrial120Dias(cidade.getNome(), cidade.getCodigo());
        return ResponseEntity.ok(Map.of(
            "cidadeNome", cidade.getNome(),
            "codigo", cidade.getCodigo(),
            "termoHomologacao", clausula
        ));
    }

    /**
     * Aprova a cidade e ativa os 120 DIAS DE TRIAL PRO MUNICIPAL,
     * ativando também todos os gestores pendentes vinculados à cidade.
     */
    @PostMapping("/cidades/{id}/aprovar")
    public ResponseEntity<?> aprovarCidade(@PathVariable String id) {
        Cidade cidadeAprovada = cidadeService.aprovarCidadeComTrial120Dias(id);

        // Ativar gestores pendentes da cidade
        List<Usuario> gestores = usuarioRepository.findByCidadeIgnoreCaseAndRole(cidadeAprovada.getCodigo(), "ADMINISTRADOR");
        for (Usuario g : gestores) {
            if (Status.PENDENTE.name().equals(g.getStatus())) {
                g.setStatus(Status.ATIVO.name());
                usuarioRepository.save(g);
            }

        }

        String clausula = cidadeService.obterClausulaTrial120Dias(cidadeAprovada.getNome(), cidadeAprovada.getCodigo());

        return ResponseEntity.ok(Map.of(
            "message", "Cidade " + cidadeAprovada.getNome() + " homologada com sucesso! 120 dias de Trial PRO liberados.",
            "cidade", cidadeAprovada,
            "gestoresAtivados", gestores.size(),
            "termoHomologacao", clausula
        ));
    }

    @PostMapping("/cidades/{id}/trial-120")
    public ResponseEntity<?> ativarTrial120Dias(@PathVariable String id) {
        Cidade cidade = cidadeService.aprovarCidadeComTrial120Dias(id);
        return ResponseEntity.ok(Map.of(
            "message", "Trial PRO de 120 dias ativado para " + cidade.getNome() + ".",
            "cidade", cidade
        ));
    }

    /**
     * Altera manualmente o plano, status e data de expiração de um município.
     */
    @PatchMapping("/cidades/{id}/plano")
    public ResponseEntity<?> atualizarPlanoManual(
            @PathVariable String id,
            @RequestBody Map<String, String> payload) {
        
        PlanoCidade novoPlano = null;
        if (payload.containsKey("plano")) {
            novoPlano = PlanoCidade.valueOf(payload.get("plano").toUpperCase());
        }

        StatusCidade novoStatus = null;
        if (payload.containsKey("status")) {
            novoStatus = StatusCidade.valueOf(payload.get("status").toUpperCase());
        }

        LocalDateTime novaExpiracao = null;
        if (payload.containsKey("contratoExpiracao")) {
            novaExpiracao = LocalDateTime.parse(payload.get("contratoExpiracao"));
        }

        Cidade atualizada = cidadeService.atualizarPlanoManual(id, novoPlano, novoStatus, novaExpiracao);

        return ResponseEntity.ok(Map.of(
            "message", "Plano da cidade " + atualizada.getNome() + " atualizado com sucesso.",
            "cidade", atualizada
        ));
    }
}
