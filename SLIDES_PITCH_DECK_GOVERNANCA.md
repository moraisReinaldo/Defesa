# 🎯 PITCH DECK (10 MINUTOS): GOVERNANÇA DE TI & LGPD
## Projeto: Defesa em Foco — Governança e Resiliência em Gestão de Desastres
**Disciplina:** Governança de TI (BRAOTI2) — Profª Letícia  
**Curso:** Análise e Desenvolvimento de Sistemas (6º Módulo)  
**Tempo Total de Apresentação:** 10 Minutos  

---

### ⏱️ Cronometragem Sugerida do Pitch (10 min):
* **Slide 1 & 2 (00:00 - 02:00):** Abertura, Contexto do Desafio e Visão Geral do Projeto
* **Slide 3 & 4 (02:00 - 04:30):** Alinhamento Estratégico e Processos COBIT 2019 Escolhidos (2 Gov + 4 Gestão)
* **Slide 5 (04:30 - 06:00):** Avaliação de Nível de Capacidade (Atual vs. Alvo com Evidências)
* **Slide 6 (06:00 - 07:15):** Matriz RACI dos Papéis do Projeto
* **Slide 7 (07:15 - 08:45):** Conformidade LGPD: Dados, Riscos, Controles e Art. 7º, VII
* **Slide 8 (08:45 - 10:00):** Roadmap de Melhorias, Conclusões e Aprendizados

---

### SLIDE 1: Capa e Identificação
* **Título:** DEFESA EM FOCO: Alinhamento Estratégico, Governança COBIT 2019 e Conformidade LGPD
* **Subtítulo:** Aplicação Prática de Governança de TI ao Sistema Integrado de Resposta a Emergências Climáticas (BRAOTI2)
* **Equipe:** Reinaldo Morais dos Santos & Grupo BRAOTI2
* **Docente:** Profª Letícia | ADS 6º Módulo
* **Fala do Apresentador (30s):**  
  *"Boa noite, professora Letícia e colegas. Hoje apresentamos a aplicação prática da Governança de Tecnologia da Informação e da LGPD no projeto Defesa em Foco, uma plataforma real desenvolvida para a Defesa Civil municipal que integra aplicativo móvel comunitário, backend escalável e infraestrutura resiliente de missão crítica."*

---

### SLIDE 2: Visão Geral do Projeto (7.2.1)
* **O Problema:** Durante enchentes e desastres naturais, os canais tradicionais (linhas telefônicas) colapsam, o socorro atrasa e a população fica sem rotas seguras de fuga.
* **A Solução "Defesa em Foco":**
  * **App Mobile Flutter:** Envio rápido de chamados com fotos georreferenciadas e **operação offline** (mapas salvos no aparelho e fila automática de envio quando a rede volta).
  * **Painel Web da Central de Comando:** Triagem automatizada com Inteligência Artificial Multimodal (Gemini) e cálculo de centróides espaciais no PostGIS.
  * **Infraestrutura Distribuída:** Cluster Docker Swarm com 3 nós em produção, balanceamento Nginx e túnel seguro Cloudflare.
* **Fala do Apresentador (1m30s):**  
  *"O Defesa em Foco não é um protótipo estático. Ele já é uma solução pronta que resolve a dor real de cidades que sofrem com alagamentos e deslizamentos. Mas tecnologia de missão crítica sem governança vira risco: por isso estruturamos o projeto com base no COBIT 2019 e na LGPD."*

---

### SLIDE 3: Mapeamento aos Objetivos de Negócio e TI (6.1)
* **Objetivos de Negócio (Impacto Público):**
  * **ON-01:** Reduzir o tempo de resposta da Defesa Civil às áreas afetadas.
  * **ON-02:** Manter disponibilidade e comunicação mesmo em situações de apagão de infraestrutura.
  * **ON-03:** Resguardar os direitos dos cidadãos e padronizar relatórios no protocolo oficial federal COBRADE.
* **Objetivos de TI Alinhados (COBIT Goals Cascade):**
  * **OT-01:** Resiliência arquitetural e alta disponibilidade (Containers Swarm + Cache Local).
  * **OT-02:** Segurança, proteção por padrão (*Privacy by Design*) e rastreabilidade com JWT e RBAC.
  * **OT-03:** Confiabilidade da informação com validação multimodal por IA e banco geoespacial.
* **Fala do Apresentador (1m):**  
  *"Aplicamos o conceito de cascata de objetivos do COBIT: cada funcionalidade desenvolvida no nosso código Java Spring Boot ou Flutter atende a um objetivo de TI, que por sua vez sustenta a meta prioritária de salvar vidas e proteger a cidade."*

---

### SLIDE 4: Processos COBIT 2019 Selecionados (7.2.2)
* **Camada de Governança (Mínimo 2 processos):**
  * 🏛️ **EDM01 – Garantir a Configuração e Manutenção do Framework de Governança:**  
    * *Por quê?* Define autoridade, papéis transparentes entre município, agentes e munícipes.
  * ⚖️ **EDM03 – Garantir a Otimização de Riscos:**  
    * *Por quê?* Estabelece o apetite e tolerância a riscos de falhas ou vazamentos em momentos de calamidade pública.
* **Camada de Gestão (Mínimo 4 processos):**
  * 🛡️ **APO12 – Gerenciar Riscos:** Planos práticos de contingência técnica (fallback de IA para PostGIS, fila assíncrona offline).
  * 🔐 **APO13 – Gerenciar Segurança da Informação:** Políticas de criptografia (BCrypt, TLS), proteção contra ataques com Rate Limiting e RBAC.
  * ⚙️ **DSS01 – Gerenciar Operações:** Sustentação do cluster Docker em 3 nós, scripts de auto-recuperação (watchdog) e monitoramento.
  * 📊 **MEA01 – Monitorar, Avaliar e Medir Desempenho e Conformidade:** Avaliação de tempos de resposta, SLAs e auditoria perante a LGPD e o padrão COBRADE.
* **Fala do Apresentador (1m30s):**  
  *"Cobrimos o espectro de ponta a ponta: no topo, a governança (EDM) define diretrizes e aceitação de risco; na base da gestão (APO, DSS e MEA), garantimos que os servidores estejam online, seguros e operando dentro da lei."*

---

### SLIDE 5: Níveis de Capacidade dos Processos (7.2.3)
* **Escala COBIT / CMMI (0 a 5):**

| Processo COBIT | Nível Atual | Nível Alvo | Evidência Técnica no Projeto | Ação para Subir de Nível |
|---|:---:|:---:|---|---|
| **EDM01 (Gov)** | **Nível 2** | Nível 3 | Níveis de acesso bem implementados no código (RBAC: Cidadão, Agente, Coordenador) | Formalizar comitê intermunicipal de governança |
| **EDM03 (Riscos Gov)** | **Nível 2** | Nível 4 | Arquitetura resiliente com contingência documentada | Desenvolver painel formal de apetite de risco |
| **APO12 (Gestão Riscos)**| **Nível 3** | Nível 4 | Cache offline no Hive + `SyncNavigatorObserver` ativo | Automação de testes de estresse e carga no CI/CD |
| **APO13 (Segurança)** | **Nível 3** | Nível 4 | Senhas com BCrypt, JWT Stateless e Cloudflare Tunnels | Implementar autenticação em 2 fatores (2FA) |
| **DSS01 (Operações)** | **Nível 3** | Nível 4 | Cluster Swarm com réplicas, Nginx balanceador e watchdog | Centralizar métricas no Prometheus + Grafana |
| **MEA01 (Medição/Conf)**| **Nível 2** | Nível 3 | Exportação oficial COBRADE e logs estruturados | Painel executivo com SLAs de tempo de resposta |

* **Fala do Apresentador (1m30s):**  
  *"Atualmente, nossos processos técnicos de gestão operam em nível 3 — estão padronizados e funcionando no código. Nossos processos de governança pura estão no nível 2 e traçamos metas claras para atingir o nível 4 através de métricas quantitativas e monitoramento em tempo real."*

---

### SLIDE 6: Matriz RACI do Projeto (7.2.4)
* **Quem é Quem no Defesa em Foco:**
  * **CID:** Cidadão / População afetada
  * **AGE:** Agente Operacional de Campo
  * **COO:** Coordenador da Defesa Civil
  * **DEV:** Equipe de Tecnologia (BRAOTI2)
  * **DPO:** Encarregado de Proteção de Dados

* **Matriz de Responsabilidades:**
  * **Definir Estratégia de TI (EDM01):** DEV executa (**R**), Coordenador responde e aprova (**A**).
  * **Gestão de Segurança (APO13):** DPO aprova e audita (**A**), DEV implementa controles (**R**).
  * **Sustentação dos Servidores (DSS01):** DEV opera e responde integralmente (**R/A**).
  * **Registro de Chamado:** Cidadão relata (**R**), agentes recebem (**I**).
  * **Triagem com IA:** DEV fornece a automação (**R**), Coordenador aprova a operação (**A**).
  * **Socorro em Campo:** Agente de rua atende (**R**), Coordenador gerencia (**A**).
* **Fala do Apresentador (1m15s):**  
  *"A matriz RACI eliminou qualquer ambiguidade de papéis: a equipe técnica não decide prioridade de atendimento na enchente; quem aprova é o coordenador da Defesa Civil. Já a segurança e conformidade de dados é auditada com poder de veto pelo Encarregado de Proteção de Dados."*

---

### SLIDE 7: Conformidade com a LGPD (7.2.5)
* **Classificação dos Dados:**
  * **Dados Comuns:** Nome, e-mail, telefone e senha criptografada (hash).
  * **Dados Geográficos e de Imagem:** Coordenadas GPS em tempo real e fotografias da área atingida.
* **Bases Legais (Art. 7º da LGPD):**
  * **Art. 7º, Inciso V:** Execução de contrato e prestação de serviços públicos.
  * **Art. 7º, Inciso VII (CRUCIAL):** *"Para a proteção da vida ou da incolumidade física do titular ou de terceiro"*.
* **Riscos & Controles Mitigadores:**
  * *Vazamento de endereço:* Cidadão anônimo para o público geral; visível estritamente a agentes credenciados.
  * *Privacidade de fotos:* Armazenamento em MinIO com URLs assinadas temporárias; anonimização facial via IA no roadmap.
  * *Direitos do Titular:* Canal oficial do DPO (`reinaldoinfra07@gmail.com`) e exclusão sob demanda.
* **Fala do Apresentador (1m30s):**  
  *"A LGPD foi tratada com a máxima seriedade. Destacamos como grande trunfo a utilização do Artigo 7º, Inciso VII — que autoriza explicitamente o tratamento de dados geográficos para proteção da vida humana em emergências, garantindo total amparo legal às ações de salvamento."*

---

### SLIDE 8: Conclusões, Aprendizados e Próximos Passos (7.2.6)
* **Principais Aprendizados do Grupo:**
  1. **Governança não é burocracia, é alicerce:** Sem o COBIT, um sistema que cai na tempestade não cumpre sua razão de existir.
  2. **Segurança por Padrão (Privacy by Design):** Tratar a LGPD desde o dia zero no banco de dados evita retrabalho e riscos jurídicos a prefeituras parceiras.
  3. **Integração Real entre Disciplinas:** Conectamos infraestrutura em Docker Swarm, engenharia de software fullstack, conformidade jurídica e extensão comunitária em um único produto viável.
* **Roadmap Imediato:**
  * 30 dias: Autenticação 2FA para todos os coordenadores.
  * 60 dias: Dashboard Prometheus/Grafana e relatório formal DPIA/RIPD.
* **Fala do Apresentador (1m15s):**  
  *"Para concluir: o Defesa em Foco demonstra que alunos de Análise e Desenvolvimento de Sistemas são capazes de projetar e operar sistemas complexos com mentalidade de governança corporativa, responsabilidade social e excelência técnica. Muito obrigado, estamos abertos às perguntas da banca!"*
