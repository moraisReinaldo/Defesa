# -*- coding: utf-8 -*-
"""
Script de geração de documento Word (.docx) formal para o Relatório de Governança de TI e LGPD
Disciplina: Governança de TI (BRAOTI2) - Profª Letícia
Projeto: Defesa em Foco
"""

import os
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, fill_hex):
    """Define a cor de fundo de uma célula da tabela"""
    shading_elm = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    cell._tc.get_or_add_tcPr().append(shading_elm)

def set_cell_margins(cell, top=120, bottom=120, left=150, right=150):
    """Define o padding interno de uma célula"""
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for margin_name, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{margin_name}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def format_table_header(row, col_widths=None):
    """Formata a linha de cabeçalho da tabela"""
    for i, cell in enumerate(row.cells):
        set_cell_background(cell, "1E3A8A")
        set_cell_margins(cell, top=140, bottom=140, left=160, right=160)
        cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        for p in cell.paragraphs:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            for run in p.runs:
                run.font.bold = True
                run.font.size = Pt(9.5)
                run.font.color.rgb = RGBColor(255, 255, 255)
                run.font.name = "Calibri"

def format_table_data(table, col_alignments=None):
    """Formata as linhas de dados da tabela"""
    for r_idx, row in enumerate(table.rows[1:]):
        bg_color = "F8FAFC" if r_idx % 2 == 1 else "FFFFFF"
        for c_idx, cell in enumerate(row.cells):
            set_cell_background(cell, bg_color)
            set_cell_margins(cell, top=100, bottom=100, left=140, right=140)
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            for p in cell.paragraphs:
                p.paragraph_format.line_spacing = 1.15
                p.paragraph_format.space_after = Pt(2)
                p.paragraph_format.space_before = Pt(2)
                if col_alignments and c_idx < len(col_alignments):
                    p.alignment = col_alignments[c_idx]
                for run in p.runs:
                    run.font.size = Pt(9)
                    run.font.name = "Calibri"
                    run.font.color.rgb = RGBColor(30, 41, 59)

def main():
    doc = Document()

    # Configuração de Página A4 (Margens ABNT: Sup 3cm, Esq 3cm, Inf 2cm, Dir 2cm)
    section = doc.sections[0]
    section.page_width = Inches(8.27)
    section.page_height = Inches(11.69)
    section.top_margin = Inches(1.18)      # 3.0 cm
    section.bottom_margin = Inches(0.79)   # 2.0 cm
    section.left_margin = Inches(1.18)     # 3.0 cm
    section.right_margin = Inches(0.79)    # 2.0 cm

    # Cabeçalho da Página
    header = section.header
    hp = header.paragraphs[0]
    hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    hrun = hp.add_run("Curso Superior de Tecnologia em ADS | Governança de TI (BRAOTI2)")
    hrun.font.name = "Calibri"
    hrun.font.size = Pt(8.5)
    hrun.font.color.rgb = RGBColor(100, 116, 139)

    # 1. Cabeçalho Institucional no Corpo
    p_inst = doc.add_paragraph()
    p_inst.paragraph_format.space_after = Pt(4)
    r_inst = p_inst.add_run("CURSO SUPERIOR DE TECNOLOGIA EM ANÁLISE E DESENVOLVIMENTO DE SISTEMAS\nDISCIPLINA: GOVERNANÇA DE TECNOLOGIA DA INFORMAÇÃO (6º MÓDULO)")
    r_inst.font.name = "Calibri"
    r_inst.font.bold = True
    r_inst.font.size = Pt(11)
    r_inst.font.color.rgb = RGBColor(15, 23, 42)

    p_proj = doc.add_paragraph()
    p_proj.paragraph_format.space_after = Pt(16)
    r_proj = p_proj.add_run("Projeto de Extensão Interdisciplinar Integrado a BRAOTI2 &bull; Instrumento Avaliativo: PR")
    r_proj.font.name = "Calibri"
    r_proj.font.size = Pt(9.5)
    r_proj.font.italic = True
    r_proj.font.color.rgb = RGBColor(71, 85, 105)

    # Caixa de Título
    p_title = doc.add_paragraph()
    p_title.paragraph_format.space_before = Pt(8)
    p_title.paragraph_format.space_after = Pt(4)
    r_title = p_title.add_run("RELATÓRIO TÉCNICO DE GOVERNANÇA DE TI (COBIT 2019) E CONFORMIDADE COM A LGPD")
    r_title.font.name = "Calibri"
    r_title.font.bold = True
    r_title.font.size = Pt(16)
    r_title.font.color.rgb = RGBColor(30, 58, 138)

    p_sub = doc.add_paragraph()
    p_sub.paragraph_format.space_after = Pt(12)
    r_sub = p_sub.add_run("Aplicação Prática ao Ecossistema Defesa em Foco — Gestão Inteligente e Resiliente de Desastres Climáticos")
    r_sub.font.name = "Calibri"
    r_sub.font.bold = True
    r_sub.font.size = Pt(12)
    r_sub.font.color.rgb = RGBColor(37, 99, 235)

    # Dados de Identificação
    meta_table = doc.add_table(rows=2, cols=2)
    meta_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    meta_table.autofit = False

    meta_cells = meta_table.rows[0].cells
    meta_cells[0].paragraphs[0].add_run("Docente Responsável: ").font.bold = True
    meta_cells[0].paragraphs[0].add_run("Profª Letícia")
    meta_cells[1].paragraphs[0].add_run("Data de Entrega: ").font.bold = True
    meta_cells[1].paragraphs[0].add_run("Novembro de 2026")

    meta_cells2 = meta_table.rows[1].cells
    meta_cells2[0].paragraphs[0].add_run("Equipe Responsável: ").font.bold = True
    meta_cells2[0].paragraphs[0].add_run("Reinaldo Morais dos Santos e Grupo BRAOTI2")
    meta_cells2[1].paragraphs[0].add_run("Ambiente Operacional: ").font.bold = True
    meta_cells2[1].paragraphs[0].add_run("Produção / Docker Swarm Ativo")

    for row in meta_table.rows:
        for cell in row.cells:
            set_cell_background(cell, "F1F5F9")
            set_cell_margins(cell, top=80, bottom=80, left=120, right=120)
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(2)
            p.paragraph_format.space_before = Pt(2)
            for r in p.runs:
                r.font.size = Pt(9)
                r.font.name = "Calibri"

    doc.add_paragraph().paragraph_format.space_after = Pt(8)

    # 1. Resumo do Projeto
    h1 = doc.add_heading("1. Resumo do Projeto BRAOTI2 (Defesa em Foco)", level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(6)

    p1 = doc.add_paragraph(
        "O Defesa em Foco é uma solução integrada de tecnologia comunitária e gestão pública, concebida para modernizar, "
        "agilizar e descentralizar os processos de prevenção, alerta precoce e pronta resposta a eventos climáticos extremos e desastres "
        "naturais (como inundações, deslizamentos de encostas e queimadas). Desenvolvido no âmbito da disciplina interdisciplinar BRAOTI2, "
        "o projeto atua como elo dinâmico entre a sociedade civil e os órgãos municipais e estaduais de Defesa Civil."
    )
    p1.paragraph_format.line_spacing = 1.25
    p1.paragraph_format.space_after = Pt(6)

    p2 = doc.add_paragraph("A arquitetura do ecossistema é composta por três frentes plenamente articuladas:")
    p2.paragraph_format.space_after = Pt(4)

    bullets = [
        ("Aplicativo Móvel Comunitário (Flutter): ", "Disponível para iOS e Android, operando com arquitetura offline-first (persistência local no Hive e mapas vetoriais cacheados pelo FMTC). Permite que os cidadãos enviem chamados com fotos georreferenciadas mesmo sem conectividade momentânea, sincronizando automaticamente assim que a rede é restabelecida."),
        ("Central de Comando e Sala de Situação Web (Spring Boot 3 + Flutter Web): ", "Painel operacional para Coordenadores da Defesa Civil. Integra Inteligência Artificial Multimodal (Google Gemini) para auditoria e agrupamento de chamados duplicados com a extensão espacial PostGIS (ST_DWithin), otimizando o envio de socorro e viaturas."),
        ("Infraestrutura Distribuída (Docker Swarm On-Premises): ", "Cluster em alta disponibilidade distribuído em 3 nós com réplicas balanceadas via Nginx, armazenamento de objetos MinIO e comunicação segura por túneis Cloudflare Tunnels (Zero Trust).")
    ]
    for bold_text, normal_text in bullets:
        bp = doc.add_paragraph(style='List Bullet')
        bp.paragraph_format.space_after = Pt(4)
        bp.paragraph_format.line_spacing = 1.2
        r_b = bp.add_run(bold_text)
        r_b.font.bold = True
        r_b.font.color.rgb = RGBColor(30, 58, 138)
        bp.add_run(normal_text)

    # 2. Objetivos de Negócio vs TI
    h2 = doc.add_heading("2. Alinhamento Estratégico: Objetivos de Negócio vs. Objetivos de TI", level=1)
    h2.paragraph_format.space_before = Pt(14)
    h2.paragraph_format.space_after = Pt(6)

    doc.add_paragraph(
        "Apoiando-se no desdobramento de metas (Goals Cascade) do COBIT 2019, o projeto vincula suas capacidades técnicas "
        "diretamente ao propósito público da Defesa Civil:"
    ).paragraph_format.space_after = Pt(6)

    t_goals = doc.add_table(rows=4, cols=2)
    t_goals.alignment = WD_TABLE_ALIGNMENT.CENTER
    t_goals.rows[0].cells[0].paragraphs[0].add_run("Objetivos de Negócio / Extensão Comunitária")
    t_goals.rows[0].cells[1].paragraphs[0].add_run("Objetivos de TI Alinhados (COBIT 2019)")
    format_table_header(t_goals.rows[0])

    goals_data = [
        ("ON-01: Reduzir em até 40% o tempo médio de triagem e envio de socorro às áreas afetadas por desastres.",
         "OT-01: Implementar triagem preditiva automática com IA Multimodal e cálculo de centróides PostGIS para agrupamento rápido de chamados."),
        ("ON-02: Garantir continuidade absoluta da comunicação durante tempestades severas e apagões locais.",
         "OT-02: Assegurar resiliência arquitetural através de cluster Swarm multi-nó e mecanismo de sincronização offline transparente no cliente móvel."),
        ("ON-03: Assegurar transparência pública, prestação de contas e conformidade com as legislações federais.",
         "OT-03: Garantir conformidade com a LGPD (Privacy by Design), autenticação RBAC via JWT e exportação de dados no padrão oficial nacional COBRADE.")
    ]
    for idx, (on_text, ot_text) in enumerate(goals_data):
        row = t_goals.rows[idx + 1]
        row.cells[0].paragraphs[0].add_run(on_text)
        row.cells[1].paragraphs[0].add_run(ot_text)

    format_table_data(t_goals)
    doc.add_paragraph().paragraph_format.space_after = Pt(6)

    # 3. Processos COBIT
    h3 = doc.add_heading("3. Processos do Framework COBIT 2019 Selecionados", level=1)
    h3.paragraph_format.space_before = Pt(14)
    h3.paragraph_format.space_after = Pt(6)

    doc.add_paragraph(
        "Para cobrir os ciclos de diretriz, planejamento, operação e controle, foram escolhidos 2 processos da Camada de Governança (EDM) "
        "e 4 processos da Camada de Gestão (APO, DSS, MEA):"
    ).paragraph_format.space_after = Pt(4)

    # Subseção Governança
    h3_1 = doc.add_heading("3.1 Camada de Governança (EDM)", level=2)
    h3_1.paragraph_format.space_before = Pt(8)
    h3_1.paragraph_format.space_after = Pt(4)

    p_edm1 = doc.add_paragraph()
    p_edm1.paragraph_format.space_after = Pt(4)
    r = p_edm1.add_run("1. EDM01 – Garantir a Configuração e Manutenção do Framework de Governança: ")
    r.font.bold = True
    p_edm1.add_run("Define a estrutura de tomada de decisão, autoridade institucional, delegação de papéis e prestação de contas (accountability) entre a prefeitura municipal, coordenadores de emergência e a equipe de desenvolvimento.")

    p_edm3 = doc.add_paragraph()
    p_edm3.paragraph_format.space_after = Pt(4)
    r = p_edm3.add_run("2. EDM03 – Garantir a Otimização de Riscos: ")
    r.font.bold = True
    p_edm3.add_run("Estabelece o apetite e os limiares de tolerância a risco da organização pública, garantindo que falhas cibernéticas ou físicas não impeçam o socorro a vidas humanas em cenários de catástrofe.")

    # Subseção Gestão
    h3_2 = doc.add_heading("3.2 Camada de Gestão (APO / DSS / MEA)", level=2)
    h3_2.paragraph_format.space_before = Pt(8)
    h3_2.paragraph_format.space_after = Pt(4)

    gest_procs = [
        ("3. APO12 – Gerenciar Riscos: ", "Operacionaliza a gestão de riscos tecnológicos, tratando falhas de sinal 4G, estouro de cotas de APIs externas (Gemini) e acionamento de planos de contingência (fallback PostGIS e fila Hive)."),
        ("4. APO13 – Gerenciar Segurança da Informação: ", "Controla o perímetro de segurança cibernética, aplicando segregação de acessos por papéis (RBAC), hash seguro de credenciais (BCrypt), tokens JWT com tempo de expiração e proteção contra abusos via RateLimitingFilter."),
        ("5. DSS01 – Gerenciar Operações: ", "Garante a execução sustentável e balanceada do cluster Docker Swarm com 3 nós, execução de rotinas de watchdog automático, monitoramento do storage MinIO e integridade das rotas de API."),
        ("6. MEA01 – Monitorar, Avaliar e Medir Desempenho e Conformidade: ", "Monitora continuamente SLAs operacionais de atendimento, disponibilidade dos nós e conformidade contínua com a LGPD e o padrão COBRADE.")
    ]
    for bold_p, text_p in gest_procs:
        p_g = doc.add_paragraph()
        p_g.paragraph_format.space_after = Pt(4)
        r_g = p_g.add_run(bold_p)
        r_g.font.bold = True
        p_g.add_run(text_p)

    doc.add_page_break()

    # 4. Avaliação de Capacidade
    h4 = doc.add_heading("4. Avaliação do Nível de Capacidade dos Processos (COBIT 2019 / CMMI)", level=1)
    h4.paragraph_format.space_before = Pt(14)
    h4.paragraph_format.space_after = Pt(6)

    doc.add_paragraph(
        "A maturidade foi avaliada com base na escala COBIT/CMMI (Nível 0 a Nível 5), correlacionando o diagnóstico atual com "
        "as evidências comprovadas no código e na infraestrutura do projeto:"
    ).paragraph_format.space_after = Pt(6)

    t_cap = doc.add_table(rows=7, cols=5)
    t_cap.alignment = WD_TABLE_ALIGNMENT.CENTER
    headers = ["Processo", "Nível Atual", "Nível Alvo", "Evidências Práticas no Projeto", "Lacunas e Plano de Ação"]
    for idx, h_text in enumerate(headers):
        t_cap.rows[0].cells[idx].paragraphs[0].add_run(h_text)
    format_table_header(t_cap.rows[0])

    cap_data = [
        ("EDM01 (Governança)", "Nível 2", "Nível 3", "Hierarquia RBAC documentada e implementada; repositório com branch protection.", "Falta comitê formalizado de governança. Ação: Instituir termo formal intermunicipal."),
        ("EDM03 (Riscos Gov)", "Nível 2", "Nível 4", "Arquitetura com tolerância a falhas implementada (failover PostGIS e planos de contingência).", "Ausência de matriz quantitativa de risco. Ação: Desenvolver painel formal de apetite de risco."),
        ("APO12 (Gestão Riscos)", "Nível 3", "Nível 4", "Resiliência offline comprovada via Hive + SyncNavigatorObserver ativo.", "Testes manuais de estresse. Ação: Integrar testes de carga automáticos (k6) no CI/CD."),
        ("APO13 (Segurança)", "Nível 3", "Nível 4", "BCrypt, JWT Stateless, Cloudflare Tunnels e Política de Privacidade publicada.", "Acesso administrativo sem 2FA. Ação: Implementar TOTP obrigatório para coordenadores."),
        ("DSS01 (Operações)", "Nível 3", "Nível 4", "Cluster Swarm 3 nós, Nginx LB, watchdog bash e Docker Visualizer.", "Métricas dispersas em logs. Ação: Implantar Prometheus + Grafana com alarmes no Telegram."),
        ("MEA01 (Conformidade)", "Nível 2", "Nível 3", "Exportação padrão COBRADE e monitoramento de saúde via Spring Actuator.", "Auditoria periódica manual. Ação: Criar painel executivo com SLAs de tempo de resposta.")
    ]
    for r_idx, data_row in enumerate(cap_data):
        row = t_cap.rows[r_idx + 1]
        for c_idx, val in enumerate(data_row):
            row.cells[c_idx].paragraphs[0].add_run(val)

    aligns = [WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT]
    format_table_data(t_cap, col_alignments=aligns)

    # 5. Matriz RACI
    h5 = doc.add_heading("5. Matriz RACI dos Processos e Operações", level=1)
    h5.paragraph_format.space_before = Pt(14)
    h5.paragraph_format.space_after = Pt(6)

    doc.add_paragraph(
        "A Matriz RACI delimita as responsabilidades entre os papéis: Cidadão (CID), Agente Operacional (AGE), Coordenador da Defesa Civil (COO), "
        "Equipe de TI/Dev (DEV) e Encarregado de Proteção de Dados (DPO):"
    ).paragraph_format.space_after = Pt(4)

    t_raci = doc.add_table(rows=10, cols=6)
    t_raci.alignment = WD_TABLE_ALIGNMENT.CENTER
    r_headers = ["Processo / Atividade Chave", "CID", "AGE", "COO", "DEV", "DPO"]
    for idx, h_text in enumerate(r_headers):
        t_raci.rows[0].cells[idx].paragraphs[0].add_run(h_text)
    format_table_header(t_raci.rows[0])

    raci_data = [
        ("EDM01: Definir diretrizes estratégicas e prioridades de TI", "I", "C", "A", "R", "C"),
        ("EDM03: Definir apetite de risco institucional e continuidade", "I", "C", "A", "C", "R"),
        ("APO12: Monitorar planos de contingência técnica e resiliência", "I", "I", "C", "R / A", "C"),
        ("APO13: Gerenciar controles de segurança da informação e RBAC", "I", "I", "C", "R", "A"),
        ("DSS01: Sustentar o cluster Swarm, backups e balanceamento", "I", "I", "I", "R / A", "I"),
        ("MEA01: Monitorar tempos de resposta (SLA) e aderência à LGPD", "I", "C", "A", "R", "A"),
        ("Operação: Registro de ocorrência com foto e geolocalização", "R", "I", "I", "I", "I"),
        ("Operação: Triagem e validação de desastre com IA / PostGIS", "I", "C", "A", "R", "I"),
        ("Operação: Despacho de viatura e atendimento no local do sinistro", "I", "R", "A", "I", "I")
    ]
    for r_idx, row_values in enumerate(raci_data):
        row = t_raci.rows[r_idx + 1]
        row.cells[0].paragraphs[0].add_run(row_values[0])
        for c_idx in range(1, 6):
            p = row.cells[c_idx].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            r_val = p.add_run(row_values[c_idx])
            r_val.font.bold = True

    raci_aligns = [WD_ALIGN_PARAGRAPH.LEFT] + [WD_ALIGN_PARAGRAPH.CENTER] * 5
    format_table_data(t_raci, col_alignments=raci_aligns)

    p_leg = doc.add_paragraph()
    p_leg.paragraph_format.space_before = Pt(4)
    p_leg.paragraph_format.space_after = Pt(8)
    r_leg = p_leg.add_run("Legenda: R = Responsible (Executor); A = Accountable (Aprovador/Dono); C = Consulted (Consultado); I = Informed (Informado).")
    r_leg.font.size = Pt(8)
    r_leg.font.italic = True
    r_leg.font.color.rgb = RGBColor(100, 116, 139)

    doc.add_page_break()

    # 6. LGPD
    h6 = doc.add_heading("6. Análise de Conformidade com a LGPD (Lei nº 13.709/2018)", level=1)
    h6.paragraph_format.space_before = Pt(14)
    h6.paragraph_format.space_after = Pt(6)

    doc.add_heading("6.1 Mapeamento de Dados e Bases Legais (Art. 7º da LGPD)", level=2).paragraph_format.space_after = Pt(4)

    t_lgpd = doc.add_table(rows=7, cols=4)
    t_lgpd.alignment = WD_TABLE_ALIGNMENT.CENTER
    lgpd_headers = ["Dado Pessoal Tratado", "Classificação", "Finalidade Operacional", "Base Legal (LGPD)"]
    for idx, h_text in enumerate(lgpd_headers):
        t_lgpd.rows[0].cells[idx].paragraphs[0].add_run(h_text)
    format_table_header(t_lgpd.rows[0])

    lgpd_data = [
        ("Nome Completo", "Dado Pessoal Comum", "Identificação do cidadão comunicante e auditoria pública", "Art. 7º, V (Execução de contrato/serviço)"),
        ("E-mail e Telefone", "Dado Pessoal Comum", "Contato de urgência e autenticação de contas", "Art. 7º, V (Execução de contrato)"),
        ("Senha de Acesso", "Dado Pessoal de Acesso", "Autenticação criptografada (hash BCrypt)", "Art. 7º, V (Segurança de sistemas)"),
        ("Geolocalização (GPS)", "Dado Geográfico", "Localização exata do desastre para resgate de vítimas", "Art. 7º, VII (Proteção da vida e integridade)"),
        ("Fotografias do Sinistro", "Dado Multimodal / Imagem", "Auditoria visual do estrago e classificação por IA", "Art. 7º, VII (Proteção da vida) c/c Art. 7º, I"),
        ("Token Push (FCM)", "Dado Técnico Identificador", "Envio instantâneo de sirenes e avisos de evacuação", "Art. 7º, VII (Proteção da vida e socorro)")
    ]
    for r_idx, row_values in enumerate(lgpd_data):
        row = t_lgpd.rows[r_idx + 1]
        for c_idx, val in enumerate(row_values):
            row.cells[c_idx].paragraphs[0].add_run(val)

    format_table_data(t_lgpd)

    # Box Art 7, VII
    p_box = doc.add_paragraph()
    p_box.paragraph_format.space_before = Pt(8)
    p_box.paragraph_format.space_after = Pt(8)
    r_box_title = p_box.add_run("Amparo Legal Estratégico: O Artigo 7º, Inciso VII da LGPD\n")
    r_box_title.font.bold = True
    r_box_title.font.color.rgb = RGBColor(30, 58, 138)
    p_box.add_run(
        "Em cenários de tragédias e emergências iminentes (enchentes repentinas, desmoronamentos de barreiras e soterramentos), "
        "a exigência de consentimento prévio formal é legalmente subsidiada pelo Artigo 7º, Inciso VII da Lei 13.709/18: "
        "'para a proteção da vida ou da incolumidade física do titular ou de terceiro'. Esse amparo concede plena sustentação jurídica "
        "à atuação do Defesa em Foco em parceria com prefeituras municipais sem criar barreiras burocráticas ao salvamento de vidas."
    )

    doc.add_heading("6.2 Riscos de Privacidade e Controles Implementados", level=2).paragraph_format.space_after = Pt(4)

    risks = [
        ("Exposição de dados residenciais do cidadão: ", "Controle: Nas consultas públicas pelo aplicativo, a identidade do autor do relato é totalmente mascarada; nomes, telefones e e-mails são visíveis exclusivamente por Coordenadores com permissão autenticada."),
        ("Captura involuntária de rostos em imagens: ", "Controle: Armazenamento em buckets privados no MinIO com URLs pré-assinadas temporárias. Em desenvolvimento filtro multimodal no Gemini para desfoque (blur) automático de feições humanas."),
        ("Atendimento aos Direitos do Titular (Art. 18): ", "Controle: Política de Privacidade oficial publicada contendo o canal formal do Encarregado de Dados (DPO) através do endereço reinaldoinfra07@gmail.com para exclusão e alteração de cadastros.")
    ]
    for r_title, r_desc in risks:
        p_r = doc.add_paragraph(style='List Bullet')
        p_r.paragraph_format.space_after = Pt(4)
        r_b = p_r.add_run(r_title)
        r_b.font.bold = True
        p_r.add_run(r_desc)

    # 7. Plano de Melhorias
    h7 = doc.add_heading("7. Plano de Melhorias e Roadmap de Governança (PDCA)", level=1)
    h7.paragraph_format.space_before = Pt(14)
    h7.paragraph_format.space_after = Pt(6)

    t_plan = doc.add_table(rows=6, cols=5)
    t_plan.alignment = WD_TABLE_ALIGNMENT.CENTER
    p_headers = ["ID / Ação Proposta", "Processo COBIT", "Prazo", "Responsável", "Resultado Esperado"]
    for idx, h_text in enumerate(p_headers):
        t_plan.rows[0].cells[idx].paragraphs[0].add_run(h_text)
    format_table_header(t_plan.rows[0])

    plan_data = [
        ("M-01: Autenticação em Dois Fatores (TOTP)", "APO13", "30 dias", "DEV", "100% dos coordenadores logando com token temporal."),
        ("M-02: Pipeline de Testes de Carga Contínuos (k6)", "APO12 / DSS01", "45 dias", "DEV", "Suportar 2.000 requisições/s sem perda de conexão."),
        ("M-03: Monitoramento com Prometheus e Grafana", "DSS01 / MEA01", "60 dias", "DEV", "Dashboard ao vivo e alertas automáticos no Telegram."),
        ("M-04: Elaboração do Relatório de Impacto (RIPD)", "EDM03 / MEA01", "60 dias", "DPO", "Documentação formal protocolada junto aos municípios."),
        ("M-05: Anonimização Facial Automática de Imagens", "APO13", "90 dias", "DEV", "Desfoque facial automático antes da gravação no MinIO.")
    ]
    for r_idx, row_values in enumerate(plan_data):
        row = t_plan.rows[r_idx + 1]
        for c_idx, val in enumerate(row_values):
            row.cells[c_idx].paragraphs[0].add_run(val)

    plan_aligns = [WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT]
    format_table_data(t_plan, col_alignments=plan_aligns)

    # 8. Conclusão
    h8 = doc.add_heading("8. Conclusões e Considerações Finais", level=1)
    h8.paragraph_format.space_before = Pt(14)
    h8.paragraph_format.space_after = Pt(6)

    doc.add_paragraph(
        "A aplicação prática dos frameworks de Governança de TI (COBIT 2019) e dos postulados da LGPD ao ecossistema Defesa em Foco "
        "comprova que sistemas de missão crítica voltados ao interesse público demandam rigor que extrapola a simples codificação funcional. "
        "A governança estabeleceu metas transparentes (Goals Cascade), estruturou papéis sem ambiguidades (RACI) e conferiu respaldo "
        "jurídico pleno com base na proteção da vida humana (Artigo 7º, VII), consolidando o projeto como referência técnica para "
        "a disciplina BRAOTI2 e para a extensão universitária em ADS."
    ).paragraph_format.space_after = Pt(8)

    # 9. Referências
    h9 = doc.add_heading("9. Referências Utilizadas", level=1)
    h9.paragraph_format.space_before = Pt(14)
    h9.paragraph_format.space_after = Pt(6)

    refs = [
        "ISACA. COBIT 2019 Framework: Governance and Management Objectives. Rolling Meadows, IL: ISACA, 2018.",
        "BRASIL. Lei Federal nº 13.709, de 14 de agosto de 2018. Lei Geral de Proteção de Dados Pessoais (LGPD). Brasília, DF, 2018.",
        "SECRETARIA NACIONAL DE PROTEÇÃO E DEFESA CIVIL (SEDEC). Instrução Normativa sobre a Classificação e Codificação Brasileira de Desastres (COBRADE). Brasília: Ministério do Desenvolvimento Regional, 2023.",
        "FERNANDO, Jeferson. Descomplicando o Docker. São Paulo: LINUXtips, 2022.",
        "PROJETO DEFESA EM FOCO. Documentação Técnica do Sistema e Política de Privacidade. Repositório oficial BRAOTI2, 2026."
    ]
    for r in refs:
        p_ref = doc.add_paragraph(style='List Bullet')
        p_ref.paragraph_format.space_after = Pt(3)
        p_ref.paragraph_format.line_spacing = 1.15
        p_ref.add_run(r)

    # Salva o arquivo Word
    output_path = r"D:\GitHub\Defesa\Relatorio_Governanca_TI_COBIT_LGPD_Defesa_em_Foco.docx"
    doc.save(output_path)
    print(f"Sucesso: Documento gerado em {output_path}")

if __name__ == "__main__":
    main()
