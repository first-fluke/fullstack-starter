# Antigravity 多智能体技能使用方法

[English](./USAGE.md) | [한국어](./USAGE.ko.md) | 简体中文 | [日本語](./USAGE.jp.md)

## 快速开始

1. **在 Antigravity IDE 中打开**
   ```bash
   antigravity open /path/to/subagent-orchestrator
   ```

2. **技能自动检测。** Antigravity 扫描 `.agent/skills/` 并索引所有可用技能。

3. **在 IDE 中聊天。** 描述您想要构建的内容。

---

## 使用示例

### 示例 1：简单的单领域任务

**您输入：**
```
"使用 Tailwind CSS 创建一个包含邮箱和密码字段的登录表单组件"
```

**发生了什么：**
- Antigravity 检测到这与 `frontend-agent` 匹配
- 技能自动加载（渐进式披露）
- 您获得一个带有 TypeScript、Tailwind、表单验证的 React 组件

### 示例 2：复杂的多领域项目

**您输入：**
```
"构建一个带用户认证的 TODO 应用"
```

**发生了什么：**

1. **工作流指南激活** — 检测到多领域复杂性
2. **PM 智能体规划** — 创建带优先级的任务分解
3. **您在智能体管理器 UI 中生成智能体**：
   - 后端智能体：JWT 认证 API
   - 前端智能体：登录和 TODO UI
4. **智能体并行工作** — 将输出保存到知识库
5. **您进行协调** — 在 `.gemini/antigravity/brain/` 中审查一致性
6. **QA 智能体审查** — 安全/性能审计
7. **修复和迭代** — 使用修正重新生成智能体

### 示例 3：Bug 修复

**您输入：**
```
"有个 bug — 点击登录显示 'Cannot read property map of undefined'"
```

**发生了什么：**

1. **debug-agent 激活** — 分析错误
2. **找到根本原因** — 组件在数据加载前遍历 `todos`
3. **提供修复** — 添加加载状态和空值检查
4. **编写回归测试** — 确保 bug 不会复发
5. **发现类似模式** — 主动修复其他 3 个组件

### 示例 4：基于 CLI 的并行执行

```bash
# 单个智能体
./scripts/spawn-subagent.sh backend "Implement JWT auth API" ./backend

# 并行智能体
./scripts/spawn-subagent.sh backend "Implement auth API" ./backend &
./scripts/spawn-subagent.sh frontend "Create login form" ./frontend &
./scripts/spawn-subagent.sh mobile "Build auth screens" ./mobile &
wait
```

**实时监控：**
```bash
# 终端（单独的终端窗口）
bun run dashboard

# 或浏览器
bun run dashboard:web
# → http://localhost:9847
```

---

## 实时监控面板

### 终端监控面板

```bash
bun run dashboard
```

使用 `fswatch` (macOS) 或 `inotifywait` (Linux) 监视 `.serena/memories/`。显示包含会话状态、智能体状态、轮次和最新活动的实时表格。当内存文件更改时自动更新。

**要求：**
- macOS: `brew install fswatch`
- Linux: `apt install inotify-tools`

### Web 监控面板

```bash
bun install          # 首次运行
bun run dashboard:web
```

在浏览器中打开 `http://localhost:9847`。功能包括：

- **实时更新** 通过 WebSocket（事件驱动，非轮询）
- **自动重连** 如果连接断开
- **Serena 主题 UI** 紫色强调色
- **会话状态** — ID 和运行中/已完成/失败状态
- **智能体表格** — 名称、状态（带彩色点）、轮次计数、任务描述
- **活动日志** — 进度和结果文件的最新更改

服务器使用 chokidar 和 debounce (100ms) 监视 `.serena/memories/`。只有更改的文件才会触发读取 — 不进行完整重新扫描。

---

## 关键概念

### 渐进式披露
Antigravity 自动将请求与技能匹配。您从不手动选择技能。只有需要的技能会加载到上下文中。

### Token 优化的技能设计
每个技能使用双层架构以获得最大 token 效率：
- **SKILL.md** (~40 行)：身份、路由、核心规则 — 立即加载
- **resources/**：执行协议、示例、检查清单、错误手册 — 按需加载

共享资源位于 `_shared/`（不是技能）中，所有智能体都可以引用：
- 4 步工作流的思维链执行协议
- 中端模型指导的少样本输入/输出示例
- "3 次失败"升级的容错恢复手册
- 结构化多步分析的推理模板
- Flash/Pro 模型层的上下文预算管理
- 通过 `verify.sh` 的自动验证
- 跨会话的经验教训积累

### 智能体管理器 UI
Antigravity IDE 中的任务控制中心面板。生成智能体、分配工作区、通过收件箱监控、审查产物。

### 知识库
智能体输出存储在 `.gemini/antigravity/brain/`。包含计划、代码、报告和协调说明。

### Serena 内存
`.serena/memories/` 中的结构化运行时状态。编排器写入会话信息、任务板、每个智能体的进度和结果。监控面板监视这些文件以进行监控。

### 工作区
智能体可以在单独的目录中工作以避免冲突：
```
./backend    → 后端智能体工作区
./frontend   → 前端智能体工作区
./mobile     → 移动端智能体工作区
```

---

## 可用技能

| 技能 | 自动激活条件 | 输出 |
|-------|-------------------|--------|
| workflow-guide | 复杂的多领域项目 | 分步智能体协调 |
| pm-agent | "plan this"、"break down" | `.agent/plan.json` |
| frontend-agent | UI、组件、样式 | React 组件、测试 |
| backend-agent | API、数据库、认证 | API 端点、模型、测试 |
| mobile-agent | 移动应用、iOS/Android | Flutter 页面、状态管理 |
| qa-agent | "review security"、"audit" | 带优先级修复的 QA 报告 |
| debug-agent | Bug 报告、错误消息 | 修复后的代码、回归测试 |
| orchestrator | CLI 子智能体执行 | `.agent/results/` 中的结果 |

---

## 工作流命令

在 Antigravity IDE 聊天中输入这些命令以触发分步工作流：

| 命令 | 描述 |
|---------|-------------|
| `/coordinate` | 通过智能体管理器 UI 进行多智能体编排 |
| `/orchestrate` | 自动化的基于 CLI 的并行智能体执行 |
| `/plan` | 带 API 契约的 PM 任务分解 |
| `/review` | 完整 QA 流程（安全、性能、可访问性、代码质量） |
| `/debug` | 结构化 bug 修复（重现 → 诊断 → 修复 → 回归测试） |

这些与**技能**（自动激活）分开。工作流让您对多步流程有显式控制。

---

## 典型工作流

### 工作流 A：单个技能

```
您: "创建一个按钮组件"
  → Antigravity 加载 frontend-agent
  → 立即获得组件
```

### 工作流 B：多智能体项目（自动）

```
您: "构建一个带认证的 TODO 应用"
  → workflow-guide 自动激活
  → PM 智能体创建计划
  → 您在智能体管理器中生成智能体
  → 智能体并行工作
  → QA 智能体审查
  → 修复问题，迭代
```

### 工作流 B-2：多智能体项目（显式）

```
您: /coordinate
  → 分步引导工作流
  → PM 规划 → 计划审查 → 智能体生成 → 监控 → QA 审查
```

### 工作流 C：Bug 修复

```
您: "登录按钮抛出 TypeError"
  → debug-agent 激活
  → 根本原因分析
  → 修复 + 回归测试
  → 检查类似模式
```

### 工作流 D：带监控面板的 CLI 编排

```
终端 1: bun run dashboard:web
终端 2: ./scripts/spawn-subagent.sh backend "task" ./backend &
        ./scripts/spawn-subagent.sh frontend "task" ./frontend &
浏览器:  http://localhost:9847 → 实时状态
```

---

## 技巧

1. **具体明确** — "用 JWT 认证、React 前端、FastAPI 后端构建 TODO 应用" 比 "做个应用" 更好
2. **多领域项目使用智能体管理器** — 不要试图在一个聊天中完成所有事情
3. **审查知识库** — 检查 `.gemini/antigravity/brain/` 的 API 一致性
4. **使用重新生成进行迭代** — 优化指令，不要重新开始
5. **使用监控面板** — `bun run dashboard` 或 `bun run dashboard:web` 来监控编排器会话
6. **分离工作区** — 为每个智能体分配其自己的目录

---

## 故障排除

| 问题 | 解决方案 |
|---------|----------|
| 技能未加载 | `antigravity open .`、检查 `.agent/skills/`、重启 IDE |
| 找不到智能体管理器 | 视图 → 智能体管理器菜单，需要 Antigravity 2026+ |
| 智能体输出不兼容 | 在知识库中审查两者，使用修正重新生成 |
| 监控面板："No agents" | 内存文件尚未创建，先运行编排器 |
| Web 监控面板无法启动 | 运行 `bun install` 安装 chokidar 和 ws |
| fswatch 未找到 | macOS: `brew install fswatch`、Linux: `apt install inotify-tools` |
| QA 报告有 50+ 问题 | 先关注 CRITICAL/HIGH，其余的稍后记录 |

---

## Bun 脚本

```bash
bun run dashboard       # 终端实时监控面板
bun run dashboard:web   # Web 监控面板 → http://localhost:9847
bun run validate        # 验证技能文件
bun run info            # 显示此使用指南
```

---

## 面向开发者（集成指南）

如果您想将这些技能集成到现有的 Antigravity 项目中，请参阅 [AGENT_GUIDE.md](./AGENT_GUIDE.md) 了解：
- 快速 3 步集成
- 完整的监控面板集成
- 针对您的技术栈定制技能
- 故障排除和最佳实践

---

**只需在 Antigravity IDE 中聊天。** 如需监控，请使用监控面板。如需 CLI 执行，请使用编排器脚本。要集成到现有项目中，请参阅 [AGENT_GUIDE.md](./AGENT_GUIDE.md)。
