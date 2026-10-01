---
description: Obriga a leitura da documentação oficial do sistema antes de codificar.
---

# Regra de Contexto do Sistema: Defesa Em Foco

**CRÍTICO:** Antes de iniciar qualquer tarefa de codificação, análise arquitetural, criação de novas funcionalidades ou depuração neste repositório, você **DEVE** ler o arquivo `DOCUMENTACAO_SISTEMA_DEFESA.md` localizado na raiz do projeto.

## Por que ler?
O arquivo `DOCUMENTACAO_SISTEMA_DEFESA.md` contém a fonte da verdade para:
1. A divisão entre o aplicativo móvel (Flutter) e o Web Dashboard (compilado pelo Flutter Web).
2. O funcionamento do mecanismo de persistência offline (Hive + FMTC).
3. A regra de negócios dos Planos SaaS gerenciados por Webhooks da Stripe (Base, Gestão, PRO).
4. O algoritmo e o uso restrito da Inteligência Artificial (Gemini) e agregação espacial (PostGIS).
5. As regras de Deploy no servidor de produção (Mac mini + Tailscale + Cloudflare Tunnels) gerenciados pelo script `update.sh` e Docker Compose.

**Ação Exigida:** Utilize a ferramenta `view_file` no arquivo `DOCUMENTACAO_SISTEMA_DEFESA.md` para carregar o contexto na sua memória antes de sugerir ou aplicar qualquer alteração estrutural no backend (Java Spring Boot) ou frontend (Flutter). Não assuma o design sem ler a documentação.

**ATUALIZAÇÃO OBRIGATÓRIA:** Sempre que você criar, alterar ou remover qualquer funcionalidade, fluxo, endpoint ou estrutura arquitetural, você **DEVE OBRIGATORIAMENTE** atualizar o arquivo `DOCUMENTACAO_SISTEMA_DEFESA.md` para refletir a nova realidade do projeto antes de concluir a sua tarefa. Nunca deixe a documentação ficar obsoleta em relação ao código.
