# Como Usar as Skills Multi-Agente do Antigravity

## Início Rápido

1. **Abrir no Antigravity IDE**
   ```bash
   antigravity open /path/to/subagent-orchestrator
   ```

2. **As skills são automaticamente detectadas.** O Antigravity escaneia `.agent/skills/` e indexa todas as skills disponíveis.

3. **Converse no IDE.** Descreva o que você quer construir.

---

## Exemplos de Uso

### Exemplo 1: Tarefa Simples de Domínio Único

**Você digita:**
```
"Crie um componente de formulário de login com campos de email e senha usando Tailwind CSS"
```

**O que acontece:**
- O Antigravity detecta que isso corresponde ao `frontend-agent`
- A skill é carregada automaticamente (Divulgação Progressiva)
- Você recebe um componente React com TypeScript, Tailwind e validação de formulário

### Exemplo 2: Projeto Complexo Multi-Domínio

**Você digita:**
```
"Construa um app TODO com autenticação de usuário"
```

**O que acontece:**

1. **O guia de workflow é ativado** — detecta a complexidade multi-domínio
2. **O Agente PM planeja** — cria decomposição de tarefas com prioridades
3. **Você gera agentes** no UI do Gerenciador de Agentes:
   - Agente Backend: API de autenticação JWT
   - Agente Frontend: Login e UI TODO
4. **Os agentes trabalham em paralelo** — salvam saídas na Base de Conhecimento
5. **Você coordena** — revisa `.gemini/antigravity/brain/` para consistência
6. **O Agente QA revisa** — auditoria de segurança/performance
7. **Corrija e itere** — regenere agentes com correções

### Exemplo 3: Correção de Bugs

**Você digita:**
```
"Tem um bug — clicar em login mostra 'Cannot read property map of undefined'"
```

**O que acontece:**

1. **O debug-agent é ativado** — analisa o erro
2. **Causa raiz encontrada** — componente faz map sobre `todos` antes dos dados carregarem
3. **Correção fornecida** — estados de loading e verificações null adicionadas
4. **Teste de regressão escrito** — garante que o bug não retorne
5. **Padrões similares encontrados** — corrige proativamente outros 3 componentes

### Exemplo 4: Execução Paralela via CLI

```bash
# Agente único
./scripts/spawn-subagent.sh backend "Implement JWT auth API" ./backend

# Agentes paralelos
./scripts/spawn-subagent.sh backend "Implement auth API" ./backend &
./scripts/spawn-subagent.sh frontend "Create login form" ./frontend &
./scripts/spawn-subagent.sh mobile "Build auth screens" ./mobile &
wait
```

**Monitore em tempo real:**
```bash
# Terminal (janela separada)
bun run dashboard

# Ou navegador
bun run dashboard:web
# → http://localhost:9847
```

---

## Dashboards em Tempo Real

### Dashboard de Terminal

```bash
bun run dashboard
```

Observa `.serena/memories/` usando `fswatch` (macOS) ou `inotifywait` (Linux). Exibe uma tabela ao vivo com status de sessão, estados de agentes, turnos e atividade mais recente. Atualiza automaticamente quando os arquivos de memória mudam.

**Requisitos:**
- macOS: `brew install fswatch`
- Linux: `apt install inotify-tools`

### Dashboard Web

```bash
bun install          # primeira vez apenas
bun run dashboard:web
```

Abra `http://localhost:9847` no navegador. Recursos:

- **Atualizações em tempo real** via WebSocket (event-driven, não polling)
- **Reconexão automática** se a conexão cair
- **UI com tema Serena** com cores de destaque roxas
- **Status da sessão** — ID e estado running/completed/failed
- **Tabela de agentes** — nome, status (com pontos coloridos), contagem de turnos, descrição da tarefa
- **Log de atividade** — alterações mais recentes dos arquivos de progresso e resultados

O servidor observa `.serena/memories/` usando chokidar com debounce (100ms). Apenas arquivos alterados disparam leituras — sem re-scan completo.

---

## Conceitos Principais

### Divulgação Progressiva
O Antigravity combina automaticamente requisições com skills. Você nunca seleciona uma skill manualmente. Apenas a skill necessária é carregada no contexto.

### Design de Skills Otimizado para Tokens
Cada skill usa uma arquitetura de duas camadas para máxima eficiência de tokens:
- **SKILL.md** (~40 linhas): Identidade, roteamento, regras principais — carregado imediatamente
- **resources/**: Protocolos de execução, exemplos, checklists, playbooks de erro — carregado sob demanda

Recursos compartilhados ficam em `_shared/` (não é uma skill) e são referenciados por todos os agentes:
- Protocolos de execução com workflow de 4 passos
- Exemplos few-shot de input/output para modelos mid-tier
- Playbooks de recuperação de erros com escalada "3 strikes"
- Templates de raciocínio para análise estruturada multi-step
- Gerenciamento de orçamento de contexto para tiers de modelo Flash/Pro
- Verificação automatizada via `verify.sh`
- Acumulação de lições aprendidas entre sessões

### UI do Gerenciador de Agentes
Dashboard de Mission Control no Antigravity IDE. Gere agentes, atribua workspaces, monitore via inbox, revise artefatos.

### Base de Conhecimento
Saídas dos agentes armazenadas em `.gemini/antigravity/brain/`. Contém planos, código, relatórios e notas de coordenação.

### Memória Serena
Estado runtime estruturado em `.serena/memories/`. O orquestrador escreve informações de sessão, boards de tarefas, progresso por agente e resultados. Os dashboards observam estes arquivos para monitoramento.

### Workspaces
Agentes podem trabalhar em diretórios separados para evitar conflitos:
```
./backend    → Workspace do Agente Backend
./frontend   → Workspace do Agente Frontend
./mobile     → Workspace do Agente Mobile
```

---

## Skills Disponíveis

| Skill | Auto-ativa para | Saída |
|-------|-----------------|-------|
| workflow-guide | Projetos complexos multi-domínio | Coordenação step-by-step de agentes |
| pm-agent | "planeje isso", "quebre" | `.agent/plan.json` |
| frontend-agent | UI, componentes, estilização | Componentes React, testes |
| backend-agent | APIs, bancos de dados, auth | Endpoints API, modelos, testes |
| mobile-agent | Apps mobile, iOS/Android | Telas Flutter, gerenciamento de estado |
| qa-agent | "revise segurança", "audite" | Relatório QA com correções priorizadas |
| debug-agent | Relatórios de bug, mensagens de erro | Código corrigido, testes de regressão |
| orchestrator | Execução CLI de sub-agentes | Resultados em `.agent/results/` |

---

## Comandos de Workflow

Digite estes no chat do Antigravity IDE para acionar workflows step-by-step:

| Comando | Descrição |
|---------|-----------|
| `/coordinate` | Orquestração multi-agente via UI do Gerenciador de Agentes |
| `/orchestrate` | Execução paralela automatizada de agentes via CLI |
| `/plan` | Decomposição de tarefas PM com contratos de API |
| `/review` | Pipeline completo de QA (segurança, performance, acessibilidade, qualidade de código) |
| `/debug` | Correção estruturada de bugs (reproduzir → diagnosticar → corrigir → teste de regressão) |

Estes são separados de **skills** (que auto-ativam). Workflows dão controle explícito sobre processos multi-step.

---

## Workflows Típicos

### Workflow A: Skill Única

```
Você: "Crie um componente de botão"
  → Antigravity carrega frontend-agent
  → Recebe componente imediatamente
```

### Workflow B: Projeto Multi-Agente (Automático)

```
Você: "Construa um app TODO com autenticação"
  → workflow-guide ativa automaticamente
  → Agente PM cria plano
  → Você gera agentes no Gerenciador de Agentes
  → Agentes trabalham em paralelo
  → Agente QA revisa
  → Corrija problemas, itere
```

### Workflow B-2: Projeto Multi-Agente (Explícito)

```
Você: /coordinate
  → Workflow guiado step-by-step
  → Planejamento PM → revisão do plano → geração de agentes → monitoramento → revisão QA
```

### Workflow C: Correção de Bugs

```
Você: "Botão de login lança TypeError"
  → debug-agent ativa
  → Análise de causa raiz
  → Correção + teste de regressão
  → Verificação de padrões similares
```

### Workflow D: Orquestração CLI com Dashboard

```
Terminal 1: bun run dashboard:web
Terminal 2: ./scripts/spawn-subagent.sh backend "task" ./backend &
            ./scripts/spawn-subagent.sh frontend "task" ./frontend &
Navegador:  http://localhost:9847 → status em tempo real
```

---

## Dicas

1. **Seja específico** — "Construa um app TODO com auth JWT, frontend React, backend FastAPI" é melhor que "faça um app"
2. **Use o Gerenciador de Agentes** para projetos multi-domínio — não tente fazer tudo em um chat
3. **Revise a Base de Conhecimento** — verifique `.gemini/antigravity/brain/` para consistência de API
4. **Itere com regerações** — refine instruções, não comece do zero
5. **Use dashboards** — `bun run dashboard` ou `bun run dashboard:web` para monitorar sessões do orquestrador
6. **Separe workspaces** — atribua seu próprio diretório a cada agente

---

## Troubleshooting

| Problema | Solução |
|---------|---------|
| Skills não carregando | `antigravity open .`, verifique `.agent/skills/`, reinicie o IDE |
| Gerenciador de Agentes não encontrado | Menu View → Agent Manager, requer Antigravity 2026+ |
| Saídas de agentes incompatíveis | Revise ambas na Base de Conhecimento, regenere com correções |
| Dashboard: "No agents" | Arquivos de memória ainda não criados, execute o orquestrador primeiro |
| Dashboard web não inicia | Execute `bun install` para instalar chokidar e ws |
| fswatch não encontrado | macOS: `brew install fswatch`, Linux: `apt install inotify-tools` |
| Relatório QA com 50+ problemas | Foque em CRITICAL/HIGH primeiro, documente o resto para depois |

---

## Scripts Bun

```bash
bun run dashboard       # Dashboard em tempo real no terminal
bun run dashboard:web   # Dashboard web → http://localhost:9847
bun run validate        # Validar arquivos de skills
bun run info            # Mostrar este guia de uso
```

---

## Para Desenvolvedores (Guia de Integração)

Se você quer integrar estas skills no seu projeto Antigravity existente, veja [AGENT_GUIDE.md](./AGENT_GUIDE.md) para:
- Integração rápida em 3 passos
- Integração completa do dashboard
- Customização de skills para sua stack tecnológica
- Troubleshooting e boas práticas

---

**Basta conversar no Antigravity IDE.** Para monitoramento, use os dashboards. Para execução CLI, use os scripts do orquestrador. Para integrar no seu projeto existente, veja [AGENT_GUIDE.md](./AGENT_GUIDE.md).
