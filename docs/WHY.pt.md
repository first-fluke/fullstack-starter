# Por que Esta Stack Tecnológica?

[English](./WHY.md) | [한국어](./WHY.ko.md) | [简体中文](./WHY.cn.md) | [日本語](./WHY.jp.md) | Português

Este documento explica o raciocínio por trás de cada escolha tecnológica neste template fullstack.

## Frontend

### Next.js 16 + React 19

- **Componentes de Servidor**: Reduz o bundle JavaScript do cliente, melhora o tempo de carregamento inicial
- **App Router**: Roteamento baseado em arquivos com layouts, estados de loading e error boundaries built-in
- **Turbopack**: Servidor de dev e builds mais rápidos comparado ao Webpack
- **React 19**: Performance melhorada com recursos concorrentes, Actions e hook `use()`

### TailwindCSS v4

- **Zero runtime**: Todos os estilos compilados em tempo de build
- **Lightning CSS**: 100x mais rápido que PostCSS-based v3
- **Configuração CSS-first**: Sintaxe CSS nativa em vez de configuração JavaScript
- **Bundles menores**: Remoção automática de estilos não utilizados

### shadcn/ui

- **Componentes copy-paste**: Sem dependência npm, propriedade total do código
- **Radix primitives**: Acessível por padrão (ARIA, navegação por teclado)
- **Tailwind-native**: Consistente com a abordagem de estilização do projeto
- **Customizável**: Fácil de modificar sem lutar com um design system

### TanStack Query

- **Cache automático**: Desduplicação, refetching em background, stale-while-revalidate
- **DevTools**: Inspector de queries built-in para debugging
- **Framework agnostic**: O mesmo modelo mental funciona no React Native se necessário
- **Atualizações otimistas**: Suporte de primeira classe para UIs responsivas

### Jotai

- **Modelo atômico bottom-up**: Construa estado combinando átomos, otimize renders baseado em dependências de átomos
- **Sem re-renders extras**: Apenas componentes inscritos em átomos alterados re-renderizam
- **TypeScript-first**: Excelente inferência de tipos
- **Leve**: ~3KB, sem providers necessários para uso básico

### TanStack Form

- **Headless & composable**: Padrão HOC `withForm` para composição de formulários modular com segurança de tipos
- **Type-safe**: Inferência completa de TypeScript para valores de formulário e validação
- **Interface simples**: API mais limpa comparada ao React Hook Form ou Formik

## Backend

### FastAPI

- **Ecossistema AI/ML**: Acesso direto às bibliotecas Python de IA (LangChain, Transformers, etc.)
- **Async-first**: Construído no Starlette com suporte nativo a async/await
- **Docs auto-geradas**: OpenAPI (Swagger) e ReDoc out of the box
- **Validação Pydantic**: Validação de request/response com type hints
- **Escalabilidade**: Fácil escalabilidade horizontal com design stateless

### SQLAlchemy (async)

- **Flexibilidade ORM**: Pode escrever SQL raw quando necessário, ORM quando conveniente
- **Suporte async**: Asyncio nativo com driver asyncpg
- **Migration-friendly**: Integração Alembic para versionamento de schema
- **Ecossistema maduro**: Battle-tested em produção por décadas

### PostgreSQL 16

- **Conformidade ACID**: Integridade de dados garantida
- **Suporte a JSON**: JSONB para dados semi-estruturados flexíveis
- **Extensão vetorial**: pgvector para embeddings de IA e busca por similaridade
- **Performance**: Query planner avançado, queries paralelas, particionamento
- **Extensões**: PostGIS, full-text search built-in

### Redis 7

- **Latência sub-milissegundo**: Armazenamento de estruturas de dados em memória
- **Versátil**: Cache, session store, pub/sub, rate limiting
- **Opções de persistência**: Snapshots RDB ou AOF para durabilidade
- **Suporte a cluster**: Escalabilidade horizontal quando necessário

### MinIO

- **Compatível com S3**: Substituto drop-in para AWS S3 API, migração perfeita para Cloud Storage de produção
- **Desenvolvimento local**: Mesma API do ambiente de produção, sem vendor lock-in durante desenvolvimento
- **Self-hosted**: Roda localmente com Docker/Podman, sem dependências externas ou contas de serviço
- **Open source**: Armazenamento de objetos enterprise-grade com controle total sobre dados

## Mobile

### Flutter 3.41.2

- **Korea eGovFrame v5**: Selecionado como framework mobile oficial pelo Korea e-Government Standard Framework
- **Versionamento flexível**: Fácil fixar e atualizar versões Flutter/Dart por projeto
- **Hot reload**: Iteração de UI em sub-segundos durante desenvolvimento
- **Performance nativa**: Compilado para ARM, sem bridge JavaScript

### Riverpod 3

- **Compile-safe**: Dependências verificadas em tempo de compilação
- **Testável**: Fácil de mockar e testar isoladamente
- **Sem context necessário**: Acesse estado de qualquer lugar sem BuildContext
- **Geração de código**: Reduz boilerplate com riverpod_generator

### go_router 17

- **Roteamento declarativo**: Navegação baseada em URL como na web
- **Deep linking**: Funciona out of the box para iOS/Android
- **Type-safe**: Parâmetros de rota gerados por código
- **Navegação aninhada**: Shell routes para navegação inferior, tabs

### Forui

- **shadcn/ui para Flutter**: Linguagem de design consistente com web (shadcn/ui)
- **Customizável**: Componentes tematizáveis com sistema de tokens similar ao Tailwind
- **Acessível**: Semânticas equivalentes a ARIA para mobile
- **Leve**: Sem dependências pesadas, apenas widgets

### Firebase Crashlytics

- **Relatório de crashes em tempo real**: Visibilidade imediata de problemas em produção
- **Breadcrumbs**: Ações do usuário que levaram ao crash
- **Desobfuscação de stack**: Stack traces legíveis para Flutter
- **Free tier**: Limites generosos para a maioria dos apps

### Fastlane

- **Releases automatizados**: Um comando para build, assinar e deploy
- **Cross-platform**: iOS e Android com o mesmo workflow
- **Integração CI**: Funciona perfeitamente com GitHub Actions
- **Gerenciamento de metadados**: Screenshots, descrições, changelogs

## Infraestrutura

### Terraform

- **Infraestrutura como Código**: Mudanças de infra versionadas e revisáveis
- **Declarativo**: Descreva o estado desejado, deixe o Terraform cuidar do resto
- **Gerenciamento de estado**: Rastreie o que está deployado, planeje antes de aplicar
- **Módulos**: Componentes de infraestrutura reutilizáveis e compartilháveis

### GCP (Cloud Run, Cloud SQL, Cloud Storage)

- **Generous free tier**: $300 de crédito para novas contas, free tier permanente para muitos serviços
- **Containers serverless**: Sem gerenciamento de servidor, escala para zero
- **Pay-per-use**: Cobrado apenas quando processando requisições
- **Banco de dados gerenciado**: Backups automáticos, HA, manutenção
- **CDN global**: Cloud CDN para assets estáticos e cache de API

### GitHub Actions + Workload Identity Federation

- **Deploy sem chaves**: Sem chaves de conta de serviço para gerenciar ou rotacionar
- **Integração nativa GitHub**: Acionado em push, PR, agendado
- **Matrix builds**: Testes paralelos em versões/plataformas
- **Marketplace**: Milhares de ações da comunidade

## Experiência do Desenvolvedor

### Toolchain Baseada em Rust

Priorizamos **velocidade** em todo o workflow de desenvolvimento escolhendo ferramentas baseadas em Rust:

- **Biome**: Linter + formatter em uma ferramenta, 100x mais rápido que ESLint + Prettier
- **uv**: Gerenciador de pacotes Python, 10-100x mais rápido que pip/poetry
- **Turbopack**: Bundler Next.js, mais rápido que Webpack
- **Lightning CSS**: Compilador TailwindCSS v4, 100x mais rápido que PostCSS

### mise

- **Suporte a monorepo poliglota**: Node, Python, Flutter, Terraform — ecossistemas diferentes, uma ferramenta
- **Versões locais por projeto**: `.mise.toml` garante ambientes consistentes entre OS durante onboarding de devs
- **Task runner**: Substitua Makefile, npm scripts, shell scripts com comandos `mise` unificados
- **Escrito em Rust**: Troca instantânea de ferramentas, sem overhead de startup

### Monorepo Poliglota

- **Repositório único**: Web (TypeScript), API (Python), Mobile (Dart), Infra (HCL) em um só lugar
- **Contextos delimitados**: Cada ecossistema de linguagem tem escopo em seu diretório, prevenindo contaminação cruzada
- **Mudanças atômicas**: Mudanças frontend + backend em um único PR
- **Ferramentas unificadas**: Mesmos comandos `mise` em todos os apps

## Trade-offs

| Escolha | Trade-off | Por que Aceitamos |
|---------|-----------|-------------------|
| Next.js vs Remix/SvelteKit | Bundle maior, mais complexidade | Ecossistema, compatibilidade React 19 |
| Next.js vs Flutter Web | Codebase separado do mobile | SEO, SSR, bundle menor, compatibilidade com ecossistema web |
| FastAPI vs Node.js | Dois runtimes (Node + Python) | Ecossistema Python AI/ML, escalabilidade |
| Flutter vs React Native | App maior, renderização customizada | Korea eGovFrame v5, versionamento flexível |

## Resumo

Esta stack otimiza para:

1. **Velocidade do desenvolvedor**: Hot reload, segurança de tipos, clientes auto-gerados
2. **Prontidão para produção**: Serviços gerenciados, escalabilidade serverless, CI/CD
3. **Escalabilidade de equipe**: Fronteiras claras, ferramentas compartilhadas, documentação
4. **Manutenibilidade de longo prazo**: Tecnologias comprovadas, comunidades ativas
