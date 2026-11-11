# 🛡️ RELATÓRIO TÉCNICO INTERDISCIPLINAR: GOVERNANÇA DE TI E LGPD (COBIT 2019)
**Projeto:** Defesa em Foco — Plataforma Inteligente de Gestão de Riscos, Crises e Desastres  
**Disciplina:** Governança de Tecnologia da Informação (Integrada ao BRAOTI2 / Projeto de Extensão)  
**Curso:** Tecnologia em Análise e Desenvolvimento de Sistemas — 6º Módulo  
**Docente:** Profª Letícia  
**Equipe Responsável:** Reinaldo Morais dos Santos e Equipe BRAOTI2  
**Data:** Novembro de 2026  

---

## 1. Resumo do Projeto (BRAOTI2 - Extensão Universitária)

O **Defesa em Foco** é uma solução tecnológica e comunitária concebida para modernizar, agilizar e democratizar a gestão de riscos e resposta a eventos climáticos extremos e desastres naturais no âmbito da Defesa Civil Municipal e Estadual.

A plataforma articula dois componentes integrados:
1. **Aplicativo Móvel Comunitário (Flutter - iOS/Android):** Permite aos cidadãos relatar ocorrências em tempo real (alagamentos, deslizamentos, quedas de árvores, queimadas), anexar fotos georreferenciadas, consultar rotas de evacuação, receber alertas push segmentados e operar em **modo offline** via *caching* local de mapas vetoriais e fila assíncrona de reportes.
2. **Painel de Comando e Sala de Situação Web (Flutter Web & Spring Boot 3):** Destinado aos coordenadores e agentes operacionais de campo, permitindo auditoria inteligente de denúncias via IA Multimodal (Google Gemini) e agrupamento espacial (*clustering* com PostGIS), despacho de viaturas, gestão de abrigos, envio de alertas de emergência e exportação padronizada de dados no protocolo federal **COBRADE**.

A infraestrutura adota arquitetura de alta resiliência baseada em containers (Docker Swarm com 3 nós distribuídos, Nginx Load Balancer, armazenamento de objetos MinIO e túnel seguro Cloudflare Tunnels), assegurando operação contínua e imune a indisponibilidades locais.

---

## 2. Alinhamento Estratégico: Objetivos de Negócio vs. Objetivos de TI

Com base no modelo de desdobramento de objetivos (*Goals Cascade*) do COBIT 2019, o projeto conecta diretamente as necessidades públicas aos serviços tecnológicos:

### 2.1 Objetivos de Negócio / Extensão Comunitária
* **ON-01 (Salvar Vidas e Mitigar Danos):** Reduzir em até 40% o tempo médio de resposta entre a notificação do cidadão e a triagem/mobilização da Defesa Civil.
* **ON-02 (Confiabilidade e Continuidade Operacional):** Manter o canal de comunicação ativo mesmo durante tempestades severas e apagões parciais de conectividade.
* **ON-03 (Transparência Pública e Conformidade Legal):** Garantir conformidade irrestrita com a LGPD (Lei nº 13.709/2018) e com o padrão oficial COBRADE da Secretaria Nacional de Proteção e Defesa Civil (SEDEC).

### 2.2 Objetivos de TI Alinhados
* **OT-01 (Disponibilidade e Resiliência da Informação):** Arquitetura distribuída com tolerância a falhas, cache de dados offline no app móvel e balanceamento de carga com replicação de serviços.
* **OT-02 (Segurança da Informação e Privacidade por Padrão - Privacy by Design):** Comunicação cifrada ponta a ponta (HTTPS/TLS), autenticação RBAC via JWT, hash de senhas com BCrypt e segregação estrita de dados públicos vs. dados cadastrais.
* **OT-03 (Precisão e Inteligência de Dados Operacionais):** Triagem automática de ocorrências utilizando IA e algoritmos geoespaciais para mitigar trotes e consolidar múltiplos chamados do mesmo evento.

---

## 3. Seleção e Justificativa de Processos do Framework COBIT 2019

Para assegurar governança sólida e gestão eficaz, foram selecionados **2 processos da Camada de Governança (EDM)** e **4 processos da Camada de Gestão (APO, BAI, DSS, MEA)**:

```
┌────────────────────────────────────────────────────────────────────────┐
│                    CAMADA DE GOVERNANÇA (EDM)                          │
│   [EDM01] Garantir Configuração e Manutenção do Framework de Governança│
│   [EDM03] Garantir Otimização de Riscos                                │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │ Alinhamento & Diretrizes
┌────────────────────────────────────▼───────────────────────────────────┐
│                     CAMADA DE GESTÃO (APO / BAI / DSS / MEA)           │
│   [APO12] Gerenciar Riscos de TI                                       │
│   [APO13] Gerenciar Segurança da Informação                            │
│   [DSS01] Gerenciar Operações                                          │
│   [MEA01] Monitorar, Avaliar e Medir Desempenho e Conformidade         │
└────────────────────────────────────────────────────────────────────────┘
```

### 3.1 Camada de Governança

#### 1. EDM01 – Garantir a Configuração e Manutenção do Framework de Governança
* **Domínio:** Avaliar, Dirigir e Monitorar (Evaluate, Direct and Monitor).
* **Justificativa no Projeto:** Como o Defesa em Foco atende prefeituras, órgãos governamentais e munícipes, faz-se imperativo definir com clareza as diretrizes de tomada de decisão, responsabilidades institucionais (RACI), transparência e prestação de contas (*accountability*). Este processo assegura que as decisões técnicas do ecossistema de TI estejam subordinadas à missão de salvar vidas e proteger a integridade pública.

#### 2. EDM03 – Garantir a Otimização de Riscos
* **Domínio:** Avaliar, Dirigir e Monitorar (Evaluate, Direct and Monitor).
* **Justificativa no Projeto:** Sistemas de emergência operam em cenários críticos onde a indisponibilidade ou corrupção de informações pode ocasionar perdas humanas. A governança precisa determinar o apetite e a tolerância a riscos do município, assegurando que riscos cibernéticos, riscos de infraestrutura física e riscos de vazamento de dados de cidadãos estejam dentro de limites estritamente controlados e auditáveis.

---

### 3.2 Camada de Gestão

#### 3. APO12 – Gerenciar Riscos
* **Domínio:** Alinhar, Planejar e Organizar (Align, Plan and Organize).
* **Justificativa no Projeto:** Implementação operacional das diretrizes de risco. Abrange a identificação sistemática de falhas em potencial: falhas de conectividade 4G durante tempestades, sobrecarga da API de inteligência artificial Gemini, indisponibilidade de nós do servidor e planos de mitigação operacional (ex: fila de sincronização *offline* do Hive e fallback para centroide PostGIS).

#### 4. APO13 – Gerenciar Segurança da Informação
* **Domínio:** Alinhar, Planejar e Organizar (Align, Plan and Organize).
* **Justificativa no Projeto:** O Defesa em Foco trata dados sensíveis e críticos (geolocalização em tempo real de vítimas e munícipes, credenciais de agentes da Defesa Civil). Este processo gerencia políticas de autenticação multifatorial, segregação de privilégios (RBAC), controle de tráfego contra força bruta (`RateLimitingFilter`), tráfego seguro via Cloudflare Tunnels e conformidade direta com a LGPD.

#### 5. DSS01 – Gerenciar Operações
* **Domínio:** Entregar, Dar Suporte e Prestar Serviços (Deliver, Service and Support).
* **Justificativa no Projeto:** Responsável pelo funcionamento diário dos serviços tecnológicos. Abrange a execução do cluster Docker Swarm (3 nós com réplicas balanceadas), monitoramento de integridade via Docker Visualizer e scripts de *watchdog*, garantia de backup do banco de dados geográfico PostGIS e volumes MinIO, e atendimento contínuo das rotas de API da Sala de Situação.

#### 6. MEA01 – Monitorar, Avaliar e Medir Desempenho e Conformidade
* **Domínio:** Monitorar, Avaliar e Medir (Monitor, Evaluate and Assess).
* **Justificativa no Projeto:** Garante que metas e SLAs de resposta a chamados de emergência sejam medidos e comparados. Além disso, audita o nível de conformidade do software perante as exigências da LGPD, os termos da ANPD e os padrões do Sistema Nacional de Proteção e Defesa Civil (COBRADE).

---

## 4. Avaliação do Nível de Capacidade dos Processos (COBIT 2019 / CMMI)

A escala de capacidade varia de **0 a 5**:
* **0 (Incompleto):** O processo não atinge seu propósito.
* **1 (Executado):** O processo atinge seu propósito de forma intuitiva/básica.
* **2 (Gerenciado):** O processo é planejado, monitorado e ajustado com entregáveis definidos.
* **3 (Definido):** O processo é formalmente documentado e padronizado em toda a organização.
* **4 (Quantitativamente Gerenciado):** O processo é controlado através de métricas e estatísticas.
* **5 (Otimizado):** O processo foca em melhoria contínua e inovação constante.

| Processo COBIT | Nível Atual | Nível Alvo | Evidências Reais no Projeto Defesa em Foco | Lacunas Identificadas | Ações de Melhoria |
|---|:---:|:---:|---|---|---|
| **EDM01** (Framework Governança) | **2** | **3** | Papéis bem delimitados no código (RBAC: Cidadão, Agente, Coordenador, Super Admin) e repositório Git documentado com papéis claros de projeto. | Falta de comitê formalizado de Governança de TI com atas e políticas publicadas para prefeituras parceiras. | Formalizar o Termo de Governança Intermunicipal e instituir o Comitê de Crise Digital. |
| **EDM03** (Otimização Riscos) | **2** | **4** | Arquitetura resiliente com mitigação de falhas (fallback PostGIS caso quota da IA expire; mapas offline). | Não há matriz quantitativa de impacto financeiro e reputacional de risco pré-calculada. | Criar painel de risco com apetite de risco formal e plano de contingência para apagões totais. |
| **APO12** (Gestão de Riscos) | **3** | **4** | Implementação de resiliência ativa: `SyncNavigatorObserver` para reenvio de relatórios offline e fallback de API. | Ausência de testes de estresse periódicos automatizados simulando enchentes com picos de 10.000 requisições/s. | Implantar testes de carga com Apache JMeter / k6 no pipeline de integração contínua (CI/CD). |
| **APO13** (Gestão da Segurança) | **3** | **4** | Criptografia de senhas (BCrypt), JWT Stateless com filtros de autorização, RateLimitingFilter e política de privacidade publicada. | Falta autenticação em dois fatores (MFA) para coordenadores e gestão centralizada de chaves via Vault. | Implementar 2FA obrigatório (TOTP) no perfil Coordenador/Admin e integrar HashiCorp Vault. |
| **DSS01** (Gestão Operações) | **3** | **4** | Cluster Swarm com 3 nós ativos, health checks automáticos de containers, Nginx balanceador e script de watchdog ativo. | Monitoramento baseado em scripts locais e visualizer; ausência de stack integrada de métricas (Prometheus/Grafana). | Integrar Prometheus + Grafana com alarmes no Telegram para alertas imediatos de queda de nós. |
| **MEA01** (Monitorar Desempenho) | **2** | **3** | Exportação de dados oficiais COBRADE e logs de eventos do sistema pelo Spring Boot Actuator. | Indicadores de governança (KPIs e KRIs) ainda são inspecionados manualmente em relatórios. | Desenvolver dashboard executivo com indicadores de SLA (tempo de atendimento da denúncia por bairro). |

---

## 5. Matriz RACI dos Processos de Governança e Gestão

### Definição dos Papéis:
* **CID:** Cidadão / Usuário da Comunidade
* **AGE:** Agente Operacional de Campo da Defesa Civil
* **COO:** Coordenador Municipal da Defesa Civil
* **DEV:** Equipe de Tecnologia / Engenharia de Software (BRAOTI2)
* **DPO:** Encarregado de Proteção de Dados e Segurança da Informação

### Legenda RACI:
* **R (Responsible):** Quem executa a atividade operacionalmente.
* **A (Accountable):** Quem responde pelo resultado final, aprova e tem autoridade decisória.
* **C (Consulted):** Quem é consultado previamente para emitir parecer técnico ou estratégico.
* **I (Informed):** Quem é comunicado após a conclusão ou ocorrência do processo.

| Processo COBIT 2019 | Atividade Principal | CID | AGE | COO | DEV | DPO |
|---|---|:---:|:---:|:---:|:---:|:---:|
| **EDM01** (Governança de TI) | Definir diretrizes estratégicas e prioridades da plataforma | I | C | **A** | R | C |
| **EDM03** (Otimização Riscos) | Estabelecer o apetite de risco institucional e continuidade | I | C | **A** | C | R |
| **APO12** (Gestão de Riscos) | Monitorar falhas técnicas, limites de API e contingência offline | I | I | C | **R / A** | C |
| **APO13** (Segurança da Informação) | Gerenciar criptografia, controle de acesso RBAC e auditoria de logs | I | I | C | R | **A** |
| **DSS01** (Operações de TI) | Manter o cluster Swarm no ar, rotinas de backup e balanceamento | I | I | I | **R / A** | I |
| **MEA01** (Monitoramento e Medição) | Avaliar métricas de tempo de resposta e conformidade LGPD | I | C | A | R | **A** |
| **Operação:** Registro de Ocorrência | Reportar incidente com foto e coordenada geográfica | **R** | I | I | I | I |
| **Operação:** Triagem com IA / PostGIS | Validar veracidade e agrupar ocorrências repetidas | I | C | **A** | R | I |
| **Operação:** Atendimento em Campo | Deslocar viatura, atualizar status e registrar parecer | I | **R** | A | I | I |

---

## 6. Análise de Conformidade com a LGPD (Lei Federal nº 13.709/2018)

### 6.1 Mapeamento e Classificação dos Dados Tratados

| Dado Coletado | Classificação | Finalidade do Tratamento | Base Legal (LGPD) |
|---|---|---|---|
| **Nome Completo** | Dado Pessoal Comum | Identificação do comunicante da ocorrência e prestação de contas à Defesa Civil | Art. 7º, V (Execução de contrato/serviço) e Art. 7º, III (Políticas Públicas) |
| **E-mail e Telefone** | Dado Pessoal Comum | Contato de urgência para confirmação de fatos e autenticação no sistema | Art. 7º, V (Execução de contrato) |
| **Senha Cadastral** | Dado Pessoal de Acesso | Controle de acesso autenticado (criptografada com hash BCrypt unidirecional) | Art. 7º, V (Segurança e execução de serviço) |
| **Geolocalização em Tempo Real (GPS)** | Dado Pessoal Geográfico / Comportamental | Posicionamento exato do cidadão ou do local do desastre para socorro rápido | Art. 7º, I (Consentimento explícito) c/c Art. 7º, VII (Proteção da Vida e Incolumidade Física) |
| **Fotografias e Registros Visuais** | Dado Pessoal (podendo conter imagem/propriedade de titulares) | Comprovação visual da ocorrência para análise multimodal de desastre | Art. 7º, I (Consentimento) c/c Art. 7º, VII (Proteção da Vida) |
| **Token Push de Notificação (FCM/OneSignal)** | Dado Técnico Identificador | Entrega instantânea de sirenes digitais e avisos de evacuação de áreas de risco | Art. 7º, VII (Proteção da Vida) |

> **Nota Jurídica Fundamental:** Em situações de tragédias iminentes (enchentes, deslizamentos), incide o **Art. 7º, Inciso VII da LGPD: "para a proteção da vida ou da incolumidade física do titular ou de terceiro"**, garantindo sustentação jurídica plena para a atuação do poder público e da ferramenta sem travas burocráticas.

---

### 6.2 Matriz de Riscos de Privacidade e Controles Implementados

```
[Riscos de Privacidade] ──────────► [Controles Técnicos Defesa em Foco]
1. Acesso indevido a dados de GPS    ──► RBAC rígido (apenas Coordenadores/Agentes autorizados)
2. Vazamento de fotos de sinistros   ──► MinIO Storage privado com URLs pré-assinadas com expiração
3. Interceptação em trânsito         ──► Criptografia obrigatória HTTPS/TLS via Cloudflare Tunnels
4. Comprometimento de credenciais    ──► Algoritmo de Hashing BCrypt (Salt de 10 rodadas) + JWT
```

1. **Risco: Exposição pública da localização residencial do munícipe denotante.**
   * *Controle Implementado:* Na interface pública do aplicativo, ocorrências exibem apenas a tipologia do sinistro (ex: "Alagamento na Rua X") e a foto da via pública; nomes, telefones e e-mails do cidadão são estritamente mascarados e visíveis apenas ao Coordenador Oficial da Defesa Civil.
2. **Risco: Anonimização de imagens contendo rostos de vítimas ou terceiros.**
   * *Controle Implementado / Planejado:* Filtro de processamento pelo modelo Gemini Multimodal para detectar e aplicar desfoque (*blur*) em feições humanas antes do armazenamento definitivo no MinIO.
3. **Risco: Solicitação de exclusão de dados pelo cidadão (Direitos do Titular - Art. 18).**
   * *Controle Implementado:* Mecanismo formal de revogação de consentimento e contato com o Encarregado de Dados (DPO) via canal oficial disponibilizado na Política de Privacidade (`reinaldoinfra07@gmail.com`).

---

### 6.3 Relacionamento entre Requisitos LGPD e Processos COBIT 2019

* **Princípio da Segurança e Confidencialidade (LGPD Art. 6º, VII e X) ↔ COBIT APO13 (Gestão de Segurança):** Implementação de barreiras cibernéticas, proteção contra injeções SQL com Hibernate/JPA e proteção contra abuso através do `RateLimitingFilter`.
* **Princípio da Finalidade e Adequação (LGPD Art. 6º, I e II) ↔ COBIT EDM01 / APO12 (Governança e Risco):** Os dados coletados limitam-se ao estritamente necessário para socorrer ocorrências e catalogar o histórico da cidade.
* **Prestação de Contas e Relatório de Impacto (LGPD Art. 38) ↔ COBIT MEA01 (Monitorar Desempenho e Conformidade):** Registro de logs de auditoria de todos os acessos dos operadores a dados sensíveis de localização.

---

## 7. Plano de Melhorias e Roadmap de Governança (Ciclo PDCA)

Com o objetivo de elevar o nível de capacidade de **2/3 para 4/5**, estabelece-se o seguinte plano de intervenções com prazos e responsáveis:

| ID | Ação Proposta | Processo COBIT | Prazo | Responsável | Métrica de Sucesso |
|---|---|---|:---:|:---:|---|
| **M-01** | Implementação de Autenticação Multifatorial (2FA/TOTP) para Coordenadores | APO13 | 30 dias | DEV | 100% dos administradores acessando com token temporal. |
| **M-02** | Implantação de Pipeline Automatizado de Testes de Carga e Estresse (k6) | APO12 / DSS01 | 45 dias | DEV | Relatório de testes suportando 2.000 requisições simultâneas sem queda de nós. |
| **M-03** | Criação do Dashboard de Métricas Operacionais com Prometheus e Grafana | DSS01 / MEA01 | 60 dias | DEV | Painel ao vivo com alertas automáticos via Telegram sobre integridade dos nós. |
| **M-04** | Elaboração do Relatório de Impacto à Proteção de Dados Pessoais (RIPD/DPIA) | EDM03 / MEA01 | 60 dias | DPO | Documento formal validado e protocolado perante a coordenação do projeto. |
| **M-05** | Algoritmo de Anonimização Automática de Rostos e Placas em Fotos | APO13 | 90 dias | DEV | 98% de faces borradas automaticamente via visão computacional do Gemini. |

---

## 8. Conclusão da Análise de Governança

A articulação prática entre o projeto de extensão **Defesa em Foco (BRAOTI2)** e os pilares de **Governança de TI (COBIT 2019)** e **Legislação Protetiva de Dados (LGPD)** demonstra que soluções de segurança pública e defesa civil exigem rigor muito além da codificação pura:
1. **Governança traz Sustentabilidade:** O desdobramento de metas (*Goals Cascade*) alinhou diretamente uma linha de código ao propósito nobre de salvar vidas e proteger municípios.
2. **Resiliência Estruturada:** O mapeamento dos processos EDM e de Gestão (APO, DSS, MEA) retirou a resiliência da casualidade, transformando-a em práticas gerenciadas (Swarm em 3 nós, fallback para PostGIS e persistência offline no Hive).
3. **Privacidade e Confiança Pública:** A conformidade com a LGPD assegura que a plataforma age sob respaldo jurídico e ético irretocável, tratando dados para proteção da vida (Art. 7º, VII) e respeitando os direitos individuais de cada cidadão brasileiro.

---

## 9. Referências Utilizadas

1. **ISACA.** *COBIT 2019 Framework: Introduction and Methodology*. Information Systems Audit and Control Association, Rolling Meadows, IL, USA, 2018.
2. **ISACA.** *COBIT 2019 Framework: Governance and Management Objectives*. ISACA, 2018.
3. **BRASIL.** *Lei nº 13.709, de 14 de agosto de 2018*. Lei Geral de Proteção de Dados Pessoais (LGPD). Presidência da República, Brasília, DF.
4. **MINISTÉRIO DA INTEGRAÇÃO E DO DESENVOLVIMENTO REGIONAL (MIDR) / SEDEC.** *Manual de Preenchimento do Sistema Integrado de Informações sobre Desastres (S2iD) e Classificação e Codificação Brasileira de Desastres (COBRADE)*. Brasília, 2023.
5. **FERNANDO, Jeferson.** *Descomplicando o Docker*. LINUXtips, 2022.
6. **PROJETO DEFESA EM FOCO.** *Documentação Técnica do Sistema e Política de Privacidade*. Repositório oficial de engenharia, 2026.
