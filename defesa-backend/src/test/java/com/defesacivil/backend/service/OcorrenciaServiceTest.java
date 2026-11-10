package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Cidade;
import com.defesacivil.backend.domain.Ocorrencia;
import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.domain.enums.OcorrenciaStatus;
import com.defesacivil.backend.domain.enums.Role;
import com.defesacivil.backend.dto.OcorrenciaRequest;
import com.defesacivil.backend.dto.SugestaoIaDto;
import com.defesacivil.backend.repository.OcorrenciaRepository;
import com.defesacivil.backend.repository.UsuarioRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Testes de Unidade (Abordagem Estrutural / Caixa-Branca) para a classe OcorrenciaService
 * referente ao Caso de Uso Principal: UC01 - Registrar e Gerenciar Ocorrência de Defesa Civil.
 *
 * NOTA SOBRE USO DE MOCKS E STUBS (Mockito):
 * - @Mock OcorrenciaRepository: Mock utilizado para simular a camada de persistência (PostgreSQL/PostGIS),
 *   incluindo stubs para save(), findById() e buscarCentroideProximo().
 * - @Mock UsuarioRepository: Mock utilizado para simular consultas de usuários autenticados e administradores.
 * - @Mock CidadeService: Stub utilizado para normalização de código IBGE/identificador municipal.
 * - @Mock NotificationService: Mock utilizado para verificar o disparo de notificações push (OneSignal)
 *   sem realizar chamadas HTTP externas reais.
 * - @Mock MinioService: Stub utilizado para simular upload Base64 e geração de URLs pré-assinadas (S3/MinIO).
 * - @Mock OcorrenciaIaService: Stub utilizado para simular o cálculo de centroide e análise multimodal Gemini.
 */
@ExtendWith(MockitoExtension.class)
class OcorrenciaServiceTest {

    // Mocks das dependências externas da camada de aplicação (Service)
    @Mock
    private OcorrenciaRepository ocorrenciaRepository;

    @Mock
    private UsuarioRepository usuarioRepository;

    @Mock
    private CidadeService cidadeService;

    @Mock
    private NotificationService notificationService;

    @Mock
    private MinioService minioService;

    @Mock
    private OcorrenciaIaService ocorrenciaIaService;

    // Classe sob teste (SUT - System Under Test) com injeção automática dos Mocks
    @InjectMocks
    private OcorrenciaService ocorrenciaService;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.clearContext();
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private void autenticarUsuario(String email, String role) {
        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                email, null, List.of(new SimpleGrantedAuthority("ROLE_" + role))
        );
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    @DisplayName("CT01 (Caminho C1 / FE01): Deve lançar exceção quando o tipo da ocorrência for nulo ou vazio")
    void deveLancarExcecaoQuandoTipoObrigatorioAusente() {
        OcorrenciaRequest request = new OcorrenciaRequest();
        request.setTipo("   ");
        request.setDescricao("Alagamento severo na via principal");

        IllegalArgumentException ex = assertThrows(
                IllegalArgumentException.class,
                () -> ocorrenciaService.registrarOcorrencia(request)
        );
        assertEquals("Tipo da ocorrência é obrigatório", ex.getMessage());
        verify(ocorrenciaRepository, never()).save(any());
    }

    @Test
    @DisplayName("CT02 (Caminho C2 / FE01): Deve lançar exceção quando a descrição for nula ou vazia")
    void deveLancarExcecaoQuandoDescricaoObrigatoriaAusente() {
        OcorrenciaRequest request = new OcorrenciaRequest();
        request.setTipo("alagamento");
        request.setDescricao("");

        IllegalArgumentException ex = assertThrows(
                IllegalArgumentException.class,
                () -> ocorrenciaService.registrarOcorrencia(request)
        );
        assertEquals("Descrição é obrigatória", ex.getMessage());
        verify(ocorrenciaRepository, never()).save(any());
    }

    @Test
    @DisplayName("CT03 (Caminho C3 / RN01, RN02, RN04): Cidadão registra ocorrência válida dentro do raio de 2km -> Status PENDENTE_APROVACAO e notifica Admins")
    void deveRegistrarOcorrenciaDeCidadaoComoPendenteENotificarAdmins() {
        OcorrenciaRequest request = new OcorrenciaRequest();
        request.setTipo("alagamento");
        request.setDescricao("Água subindo rapidamente na Rua Central");
        request.setLatitude(-22.9300);
        request.setLongitude(-46.2700);
        request.setLatitudeEnvio(-22.9305); // ~60m de distância (<= 2000m)
        request.setLongitudeEnvio(-46.2705);
        request.setCidade("joanopolis");

        // Stub: PostGIS retorna 2 relatos anteriores no raio de 200m
        when(ocorrenciaRepository.buscarCentroideProximo(anyString(), anyDouble(), anyDouble(), eq(200), eq(2)))
                .thenReturn(new Object[]{2, -22.9302, -46.2702});
        when(cidadeService.normalizarCodigoCidade("joanopolis")).thenReturn("joanopolis");
        when(cidadeService.buscarPorCodigo("joanopolis")).thenReturn(Optional.of(new Cidade()));

        Usuario admin = new Usuario();
        admin.setId("admin-01");
        admin.setRole(Role.ADMINISTRADOR.name());
        when(usuarioRepository.findByCidadeAndRole("joanopolis", Role.ADMINISTRADOR.name()))
                .thenReturn(List.of(admin));

        when(ocorrenciaRepository.save(any(Ocorrencia.class))).thenAnswer(inv -> {
            Ocorrencia o = inv.getArgument(0);
            o.setId("oc-100");
            return o;
        });

        Ocorrencia resultado = ocorrenciaService.registrarOcorrencia(request);

        assertNotNull(resultado);
        assertEquals("oc-100", resultado.getId());
        assertEquals(OcorrenciaStatus.PENDENTE_APROVACAO.name(), resultado.getStatus());
        assertEquals("1.2.3.0.0", resultado.getCobrade()); // RN04: COBRADE resolvido automaticamente
        verify(notificationService, times(1)).sendPushNotification(
                eq("admin-01"),
                eq("Nova Ocorrência Pendente"),
                contains("joanopolis")
        );
    }

    @Test
    @DisplayName("CT04 (Caminho C4 / RN01): Deve marcar origemSuspeita=true e reter em PENDENTE_APROVACAO quando distância GPS > 2000m mesmo criado por Agente")
    void deveMarcarOrigemSuspeitaQuandoDistanciaMaiorQue2Km() {
        autenticarUsuario("agente@defesa.gov.br", "AGENTE");

        Usuario agente = new Usuario();
        agente.setId("ag-01");
        agente.setEmail("agente@defesa.gov.br");
        agente.setRole(Role.AGENTE.name());
        agente.setCidade("joanopolis");

        when(usuarioRepository.findByEmail("agente@defesa.gov.br")).thenReturn(Optional.of(agente));
        when(cidadeService.normalizarCodigoCidade(anyString())).thenReturn("joanopolis");
        when(ocorrenciaRepository.save(any(Ocorrencia.class))).thenAnswer(inv -> inv.getArgument(0));

        OcorrenciaRequest request = new OcorrenciaRequest();
        request.setTipo("deslizamento");
        request.setDescricao("Deslizamento de encosta no km 12");
        request.setLatitude(-22.9300);
        request.setLongitude(-46.2700);
        // Coordenada de envio a ~15km de distância (> 2000m)
        request.setLatitudeEnvio(-23.0500);
        request.setLongitudeEnvio(-46.3500);
        request.setCriadoPorAgente(true);

        Ocorrencia salva = ocorrenciaService.registrarOcorrencia(request);

        // Como origemSuspeita = true, a auto-aprovação é bloqueada (RN01 + RN03)
        assertEquals(OcorrenciaStatus.PENDENTE_APROVACAO.name(), salva.getStatus());
        assertEquals("1.3.2.1.1", salva.getCobrade());
    }

    @Test
    @DisplayName("CT05 (Caminho C5 / RN03, RN05): Agente/Admin autenticado registra ocorrência atual -> Auto-aprovação (APROVADA) e vinculação à cidade do agente")
    void deveAutoAprovarOcorrenciaCriadaPorAgenteEmTempoReal() {
        autenticarUsuario("coordenador@joanopolis.sp.gov.br", "ADMINISTRADOR");

        Usuario coord = new Usuario();
        coord.setId("coord-01");
        coord.setEmail("coordenador@joanopolis.sp.gov.br");
        coord.setRole(Role.ADMINISTRADOR.name());
        coord.setCidade("joanopolis");

        when(usuarioRepository.findByEmail("coordenador@joanopolis.sp.gov.br")).thenReturn(Optional.of(coord));
        when(cidadeService.normalizarCodigoCidade(anyString())).thenReturn("joanopolis");
        when(minioService.uploadBase64Image(anyString(), eq("ocorrencias"))).thenReturn("ocorrencias/foto123.jpg");
        when(minioService.getPresignedUrl("ocorrencias/foto123.jpg")).thenReturn("https://fotos.rhprogramer.com.br/ocorrencias/foto123.jpg");
        when(ocorrenciaRepository.save(any(Ocorrencia.class))).thenAnswer(inv -> inv.getArgument(0));

        OcorrenciaRequest request = new OcorrenciaRequest();
        request.setTipo("queda_arvore");
        request.setDescricao("Árvore caída obstruindo fiação elétrica");
        request.setLatitude(-22.9310);
        request.setLongitude(-46.2710);
        request.setCidade("outra_cidade"); // RN05: deve sobrescrever para a cidade do Admin (joanopolis)
        request.setCaminhoFoto("data:image/jpeg;base64,/9j/4AAQSkZJRg==");
        request.setCriadoPorAgente(true);

        Ocorrencia resultado = ocorrenciaService.registrarOcorrencia(request);

        assertEquals(OcorrenciaStatus.APROVADA.name(), resultado.getStatus());
        assertEquals("joanopolis", resultado.getCidade());
        assertEquals("1.3.1.1.1", resultado.getCobrade());
        assertEquals("https://fotos.rhprogramer.com.br/ocorrencias/foto123.jpg", resultado.getCaminhoFoto());
        verify(minioService, times(1)).uploadBase64Image(anyString(), eq("ocorrencias"));
    }

    @Test
    @DisplayName("CT06 (Caminho C6 / RN03): Registro retroativo por Administrador (data no passado > 2 min) -> Entra diretamente como RESOLVIDA")
    void deveDefinirStatusResolvidaParaOcorrenciaNoPassadoCriadaPorAdmin() {
        autenticarUsuario("admin@joanopolis.sp.gov.br", "ADMINISTRADOR");

        OcorrenciaRequest request = new OcorrenciaRequest();
        request.setTipo("incendio_vegetacao");
        request.setDescricao("Foco de incêndio controlado pela brigada municipal");
        request.setLatitude(-22.9200);
        request.setLongitude(-46.2600);
        request.setDataHora(LocalDateTime.now().minusDays(2).toString());
        request.setCriadoPorAgente(true);

        when(ocorrenciaRepository.save(any(Ocorrencia.class))).thenAnswer(inv -> inv.getArgument(0));

        Ocorrencia resultado = ocorrenciaService.registrarOcorrencia(request);

        assertEquals(OcorrenciaStatus.RESOLVIDA.name(), resultado.getStatus());
        assertNotNull(resultado.getDataResolucao());
        assertEquals("1.4.1.1.0", resultado.getCobrade());
    }

    @Test
    @DisplayName("CT07 (Ciclo de Estados GE - S1): Fluxo completo de transição de estados: Aprovar -> Registrar Chegada -> Resolver -> Reativar")
    void deveExecutarCicloCompletoDeTransicaoDeEstadosDaOcorrencia() {
        autenticarUsuario("admin@joanopolis.sp.gov.br", "SUPER_ADMIN");

        Ocorrencia oc = new Ocorrencia();
        oc.setId("oc-200");
        oc.setTipo("alagamento");
        oc.setCidade("joanopolis");
        oc.setUsuarioId("cid-01");
        oc.setStatus(OcorrenciaStatus.PENDENTE_APROVACAO.name());

        Usuario cidadao = new Usuario();
        cidadao.setId("cid-01");

        when(ocorrenciaRepository.findById("oc-200")).thenReturn(Optional.of(oc));
        when(usuarioRepository.findById("cid-01")).thenReturn(Optional.of(cidadao));
        when(ocorrenciaRepository.save(any(Ocorrencia.class))).thenAnswer(inv -> inv.getArgument(0));

        // 1. Transição PENDENTE_APROVACAO -> APROVADA (com ajuste de coordenadas IA)
        Ocorrencia aprovada = ocorrenciaService.aprovarOcorrencia("oc-200", -22.9315, -46.2715);
        assertEquals(OcorrenciaStatus.APROVADA.name(), aprovada.getStatus());
        assertEquals(-22.9315, aprovada.getLatitude());

        // 2. Transição APROVADA -> TRABALHANDO_ATUALMENTE (chegada do agente em campo)
        Ocorrencia emAtendimento = ocorrenciaService.registrarChegadaAgente("oc-200", "Equipe posicionada isolando a área");
        assertEquals(OcorrenciaStatus.TRABALHANDO_ATUALMENTE.name(), emAtendimento.getStatus());
        assertTrue(emAtendimento.isAgenteNoLocal());
        assertNotNull(emAtendimento.getDataChegadaAgente());

        // 3. Transição TRABALHANDO_ATUALMENTE -> RESOLVIDA
        Ocorrencia resolvida = ocorrenciaService.resolverOcorrencia("oc-200", "Drenagem concluída e via liberada");
        assertEquals(OcorrenciaStatus.RESOLVIDA.name(), resolvida.getStatus());
        assertNotNull(resolvida.getDataResolucao());

        // 4. Transição RESOLVIDA -> APROVADA (Reativação)
        Ocorrencia reativada = ocorrenciaService.reativarOcorrencia("oc-200");
        assertEquals(OcorrenciaStatus.APROVADA.name(), reativada.getStatus());
        assertNull(reativada.getDataResolucao());
    }

    @Test
    @DisplayName("CT08 (Integração IA / RN06): Deve calcular sugestão de posicionamento via OcorrenciaIaService e persistir cache na entidade")
    void deveCalcularEPersistirSugestaoIa() {
        autenticarUsuario("admin@joanopolis.sp.gov.br", "SUPER_ADMIN");

        Ocorrencia oc = new Ocorrencia();
        oc.setId("oc-300");
        oc.setTipo("deslizamento");
        oc.setCidade("joanopolis");
        oc.setProcessadaIa(false);

        SugestaoIaDto sugestaoMock = new SugestaoIaDto(-22.9350, -46.2750, 0.92, "Centroide validado por visão computacional", 3);
        when(ocorrenciaRepository.findById("oc-300")).thenReturn(Optional.of(oc));
        when(ocorrenciaIaService.calcularSugestao(eq(oc), any())).thenReturn(sugestaoMock);

        SugestaoIaDto retorno = ocorrenciaService.obterSugestaoIa("oc-300");

        assertEquals(0.92, retorno.getConfianca());
        assertEquals(3, retorno.getTotalRelatosCluster());
        assertTrue(oc.isProcessadaIa());
        verify(ocorrenciaRepository, times(1)).save(oc);
    }

    @Test
    @DisplayName("CT09 (Segurança / RN05): Deve bloquear tentativa de Agente gerenciar ocorrência de outro município (SecurityException)")
    void deveBloquearAcessoDeAgenteDeOutraJurisdicao() {
        autenticarUsuario("agente_sp@defesa.gov.br", "AGENTE");

        Usuario agenteSp = new Usuario();
        agenteSp.setId("ag-sp");
        agenteSp.setEmail("agente_sp@defesa.gov.br");
        agenteSp.setRole(Role.AGENTE.name());
        agenteSp.setCidade("sao_paulo");

        Ocorrencia ocJoanopolis = new Ocorrencia();
        ocJoanopolis.setId("oc-400");
        ocJoanopolis.setCidade("joanopolis");

        when(ocorrenciaRepository.findById("oc-400")).thenReturn(Optional.of(ocJoanopolis));
        when(usuarioRepository.findByEmail("agente_sp@defesa.gov.br")).thenReturn(Optional.of(agenteSp));
        when(cidadeService.normalizarCodigoCidade("sao_paulo")).thenReturn("sao_paulo");
        when(cidadeService.normalizarCodigoCidade("joanopolis")).thenReturn("joanopolis");

        assertThrows(SecurityException.class, () -> ocorrenciaService.resolverOcorrencia("oc-400", "Parecer indevido"));
    }
}
