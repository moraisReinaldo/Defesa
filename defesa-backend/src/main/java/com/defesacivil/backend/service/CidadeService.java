package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Cidade;
import com.defesacivil.backend.domain.enums.PlanoCidade;
import com.defesacivil.backend.domain.enums.StatusCidade;
import com.defesacivil.backend.repository.CidadeRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

@Service
public class CidadeService {

    private final CidadeRepository repository;

    public CidadeService(CidadeRepository repository) {
        this.repository = repository;
    }

    public List<Cidade> listarTodas() {
        return repository.findAll();
    }

    public List<Cidade> listarPendentes() {
        return repository.findByStatus(StatusCidade.PENDENTE_APROVACAO);
    }

    public Optional<Cidade> buscarPorId(String id) {
        return repository.findById(id);
    }
    
    public Optional<Cidade> buscarPorNome(String nome) {
        return repository.findByNomeIgnoreCase(nome);
    }

    public Optional<Cidade> buscarPorCodigo(String codigo) {
        return repository.findByCodigoIgnoreCase(codigo);
    }

    public Cidade salvar(Cidade cidade) {
        return repository.save(cidade);
    }

    public void deletar(String id) {
        repository.deleteById(id);
    }

    @Transactional
    public Cidade buscarOuCriarCidade(String nomeOuCodigo) {
        if (nomeOuCodigo == null || nomeOuCodigo.isBlank()) return null;
        String codigoNorm = normalizarCodigoCidade(nomeOuCodigo);
        String nomeNorm = obterNomeCidade(nomeOuCodigo);

        return repository.findByCodigoIgnoreCase(codigoNorm)
            .orElseGet(() -> {
                Cidade nova = new Cidade(codigoNorm, nomeNorm);
                nova.setStatus(StatusCidade.PENDENTE_APROVACAO);
                nova.setPlano(PlanoCidade.BASE_GRATUITO);
                return repository.save(nova);
            });
    }

    @Transactional
    public Cidade aprovarCidadeComTrial90Dias(String cidadeId) {
        Cidade cidade = repository.findById(cidadeId)
            .orElseThrow(() -> new IllegalArgumentException("Cidade não encontrada com ID: " + cidadeId));

        LocalDateTime agora = LocalDateTime.now();
        cidade.setStatus(StatusCidade.TRIAL_ATIVO);
        cidade.setPlano(PlanoCidade.PRO_MUNICIPAL);
        cidade.setTrialInicio(agora);
        cidade.setTrialFim(agora.plusDays(90));

        return repository.save(cidade);
    }

    @Transactional
    public Cidade atualizarPlanoManual(String cidadeId, PlanoCidade novoPlano, StatusCidade novoStatus, LocalDateTime novaExpiracao) {
        Cidade cidade = repository.findById(cidadeId)
            .orElseThrow(() -> new IllegalArgumentException("Cidade não encontrada com ID: " + cidadeId));

        if (novoPlano != null) cidade.setPlano(novoPlano);
        if (novoStatus != null) cidade.setStatus(novoStatus);
        if (novaExpiracao != null) cidade.setContratoExpiracao(novaExpiracao);

        return repository.save(cidade);
    }

    public String obterClausulaTrial90Dias(String cidadeNome, String codigo) {
        String dataHoje = LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
        String dataFim = LocalDateTime.now().plusDays(90).format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));

        return "=========================================================================================\n" +
               "TERMO DE HOMOLOGAÇÃO E COOPERAÇÃO TÉCNICA - DEGUSTAÇÃO OPERACIONAL (TRIAL 90 DIAS)\n" +
               "PLATAFORMA INTEGRADA DE PROTEÇÃO E DEFESA CIVIL - DEFESA EM FOCO\n" +
               "=========================================================================================\n\n" +
               "MUNICÍPIO BENEFICIÁRIO: " + cidadeNome + " (" + codigo + ")\n" +
               "PERÍODO DE VIGÊNCIA: 90 DIAS CORRIDOS (De " + dataHoje + " até " + dataFim + ")\n" +
               "STATUS DO PLANO: PLANO PRO MUNICIPAL (ACESSO TOTAL LIBERADO)\n\n" +
               "CLÁUSULA PRIMEIRA - DO OBJETO E CONCESSÃO\n" +
               "O presente instrumento formaliza a liberação de acesso pleno, gratuito e irrestrito à plataforma\n" +
               "Defesa em Foco sob o PLANO PRO MUNICIPAL pelo prazo improrrogável de 90 (noventa) dias corridos,\n" +
               "em favor da Coordenadoria Municipal de Defesa Civil do Município de " + cidadeNome + ".\n\n" +
               "CLÁUSULA SEGUNDA - DA GRATUIDADE E AUSÊNCIA DE ÔNUS\n" +
               "A disponibilização do período de avaliação dar-se-á a título de cooperação e validação tecnológica,\n" +
               "sem qualquer cobrança, taxa de implantação, exigência de contrapartida financeira ou obrigação de\n" +
               "permanência futura para os cofres públicos municipais durante a vigência deste período.\n\n" +
               "CLÁUSULA TERCEIRA - DOS RECURSOS E MÓDULOS LIBERADOS\n" +
               "Durante o período de 90 dias, o MUNICÍPIO terá acesso irrestrito aos seguintes módulos avançados:\n" +
               "  I - Gestão Integrada de Gabinete e Painel Web para até 5 (cinco) Gestores credenciados;\n" +
               "  II - Módulo de Equipe de Rua com Agentes de Campo ilimitados, despacho, mapa e rotas em tempo real;\n" +
               "  III - Sistema de Alertas de Emergência e Notificações Push à População via OneSignal;\n" +
               "  IV - Cadastro e Gerenciamento Georreferenciado de Pontos de Apoio, Abrigos e Zonas de Risco (POIs);\n" +
               "  V - Exportação Oficial de Ocorrências no padrão COBRADE e integração com o S2ID (MDR/Federal);\n" +
               "  VI - Isenção total de anúncios publicitários para todos os munícipes e agentes na jurisdição.\n\n" +
               "CLÁUSULA QUARTA - DA PROTEÇÃO DE DADOS (LGPD) E CONFIDENCIALIDADE\n" +
               "As partes declaram cumprimento integral à Lei Geral de Proteção de Dados (Lei Federal nº 13.709/2018).\n" +
               "Os dados de ocorrências, munícipes e agentes coletados permanecem sob custódia e titularidade do\n" +
               "MUNICÍPIO, sendo assegurada a exportação integral das informações a qualquer tempo.\n\n" +
               "CLÁUSULA QUINTA - DO ENCERRAMENTO E TRANSIÇÃO\n" +
               "Ao término dos 90 (noventa) dias de vigência:\n" +
               "  I - O MUNICÍPIO poderá formalizar a contratação definitiva por meio de Dispensa de Licitação,\n" +
               "      com fulcro no art. 75, inciso II, da Lei Federal nº 14.133/2021 (Nova Lei de Licitações);\n" +
               "  II - Não havendo interesse na contratação onerosa, o acesso do MUNICÍPIO será automaticamente\n" +
               "      convertido para o Plano Base Gratuito, resguardado o histórico de ocorrências registradas,\n" +
               "      sem aplicação de qualquer multa, penalidade ou sanção administrativa.\n\n" +
               "Homologado e Registrado nos servidores oficiais Defesa em Foco em " + dataHoje + ".\n" +
               "=========================================================================================";
    }

    public String normalizarCodigoCidade(String cidade) {
        if (cidade == null || cidade.isBlank()) return null;
        String limpa = cidade.trim();
        return repository.findByCodigoIgnoreCase(limpa)
            .or(() -> repository.findByNomeIgnoreCase(limpa))
            .map(Cidade::getCodigo)
            .orElseGet(() -> {
                String upper = limpa.toUpperCase();
                switch (upper) {
                    case "PIRACAIA": return "PIR";
                    case "JOANOPOLIS":
                    case "JOANÓPOLIS": return "JOA";
                    case "ATIBAIA": return "ATI";
                    case "BRAGANÇA PAULISTA":
                    case "BRAGANCA PAULISTA": return "BP";
                    case "NAZARÉ PAULISTA":
                    case "NAZARE PAULISTA": return "NAZ";
                    case "TUIUTI": return "TUI";
                    case "VARGEM": return "VAR";
                    default: return upper;
                }
            });
    }

    public String obterNomeCidade(String cidade) {
        if (cidade == null || cidade.isBlank()) return null;
        String limpa = cidade.trim();
        return repository.findByCodigoIgnoreCase(limpa)
            .or(() -> repository.findByNomeIgnoreCase(limpa))
            .map(Cidade::getNome)
            .orElseGet(() -> {
                String upper = limpa.toUpperCase();
                switch (upper) {
                    case "PIR": return "Piracaia";
                    case "JOA": return "Joanópolis";
                    case "ATI": return "Atibaia";
                    case "BP": return "Bragança Paulista";
                    case "NAZ": return "Nazaré Paulista";
                    case "TUI": return "Tuiuti";
                    case "VAR": return "Vargem";
                    default: return limpa;
                }
            });
    }
}

