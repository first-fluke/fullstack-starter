# 为什么选择这个技术栈？

[English](./WHY.md) | [한국어](./WHY.ko.md) | 简体中文 | [日本語](./WHY.jp.md)

本文档解释了这个全栈启动模板中每项技术选择的原因。

## 前端

### Next.js 16 + React 19

- **服务端组件**：减少客户端 JavaScript 包大小，提升初始加载时间
- **App Router**：内置基于文件的路由、布局、加载状态和错误边界
- **Turbopack**：比 Webpack 更快的开发服务器和构建速度
- **React 19**：并发特性、Actions 和 `use()` hook 带来性能提升

### TailwindCSS v4

- **零运行时**：所有样式在构建时编译
- **Lightning CSS**：比基于 PostCSS 的 v3 快 100 倍
- **CSS 优先配置**：原生 CSS 语法替代 JavaScript 配置
- **更小的包**：自动移除未使用的样式

### shadcn/ui

- **复制粘贴组件**：无 npm 依赖，完全拥有代码
- **Radix 基础组件**：默认无障碍（ARIA、键盘导航）
- **Tailwind 原生**：与项目样式方案一致
- **可定制**：易于修改，无需与设计系统对抗

### TanStack Query

- **自动缓存**：去重、后台重新获取、stale-while-revalidate
- **DevTools**：内置查询检查器用于调试
- **框架无关**：相同的心智模型也可用于 React Native
- **乐观更新**：对响应式 UI 的一流支持

### Jotai

- **自下而上的原子模型**：通过组合原子构建状态，根据原子依赖优化渲染
- **无额外重渲染**：只有订阅了变化原子的组件才会重渲染
- **TypeScript 优先**：优秀的类型推导
- **轻量级**：约 3KB，基本使用无需 Provider

### TanStack Form

- **无头且可组合**：`withForm` HOC 模式用于模块化表单组合和类型安全
- **类型安全**：表单值和验证的完整 TypeScript 推导
- **简洁接口**：相比 React Hook Form 或 Formik 更清晰的 API

## 后端

### FastAPI

- **AI/ML 生态系统**：直接访问 Python 的 AI 库（LangChain、Transformers 等）
- **异步优先**：基于 Starlette，原生支持 async/await
- **自动生成文档**：开箱即用的 OpenAPI (Swagger) 和 ReDoc
- **Pydantic 验证**：使用类型提示进行请求/响应验证
- **可扩展性**：无状态设计易于水平扩展

### SQLAlchemy (异步)

- **ORM 灵活性**：需要时可写原生 SQL，方便时使用 ORM
- **异步支持**：使用 asyncpg 驱动原生支持 asyncio
- **迁移友好**：Alembic 集成进行模式版本管理
- **成熟的生态系统**：在生产环境中经过数十年实战检验

### PostgreSQL 16

- **ACID 合规性**：保证数据完整性
- **JSON 支持**：JSONB 用于灵活的半结构化数据
- **向量扩展**：pgvector 用于 AI 嵌入和相似性搜索
- **性能**：高级查询规划器、并行查询、分区
- **扩展**：内置 PostGIS、全文搜索

### Redis 7

- **亚毫秒级延迟**：内存数据结构存储
- **多功能**：缓存、会话存储、发布/订阅、速率限制
- **持久化选项**：RDB 快照或 AOF 保证持久性
- **集群支持**：需要时水平扩展

### MinIO

- **S3 兼容**：AWS S3 API 的即插即用替代品，无缝迁移到生产云存储
- **本地开发**：与生产环境相同的 API，开发期间无供应商锁定
- **自托管**：使用 Docker/Podman 本地运行，无需外部依赖或服务账号
- **开源**：企业级对象存储，完全数据控制

## 移动端

### Flutter 3.41.2

- **韩国 eGovFrame v5**：被韩国电子政府标准框架选为官方移动框架
- **灵活的版本控制**：每个项目可轻松固定和升级 Flutter/Dart 版本
- **热重载**：开发期间亚秒级 UI 迭代
- **原生性能**：编译为 ARM，无 JavaScript 桥接

### Riverpod 3

- **编译时安全**：依赖项在编译时检查
- **可测试**：易于隔离模拟和测试
- **无需 context**：无需 BuildContext 即可从任何地方访问状态
- **代码生成**：使用 riverpod_generator 减少样板代码

### go_router 17

- **声明式路由**：类似 Web 的基于 URL 的导航
- **深度链接**：开箱即用在 iOS/Android 上工作
- **类型安全**：代码生成的路由参数
- **嵌套导航**：用于底部导航、标签页的 Shell 路由

### Forui

- **Flutter 的 shadcn/ui**：与 Web (shadcn/ui) 一致的设计语言
- **可定制**：使用类似 Tailwind 的令牌系统进行主题化组件
- **无障碍**：移动端的 ARIA 等效语义
- **轻量级**：无重量级依赖，仅为 widget

### Firebase Crashlytics

- **实时崩溃报告**：生产问题的即时可见性
- **面包屑**：导致崩溃的用户操作
- **堆栈符号化**：可读的 Flutter 堆栈跟踪
- **免费层**：大多数应用宽松的限制

### Fastlane

- **自动化发布**：一键构建、签名和部署
- **跨平台**：iOS 和 Android 使用相同的工作流
- **CI 集成**：与 GitHub Actions 无缝协作
- **元数据管理**：截图、描述、更新日志

## 基础设施

### Terraform

- **基础设施即代码**：版本控制、可审查的基础设施变更
- **声明式**：描述期望状态，让 Terraform 处理其余
- **状态管理**：跟踪已部署内容，应用前规划
- **模块**：可重用、可共享的基础设施组件

### GCP (Cloud Run, Cloud SQL, Cloud Storage)

- **慷慨的免费层**：新账号 $300 额度，许多服务永久免费
- **无服务器容器**：无需服务器管理，缩放到零
- **按使用付费**：只在处理请求时收费
- **托管数据库**：自动备份、高可用、维护
- **全球 CDN**：静态资源和 API 缓存的云 CDN

### GitHub Actions + Workload Identity Federation

- **无密钥部署**：无需管理或轮换服务账号密钥
- **原生 GitHub 集成**：在推送、PR、定时触发
- **矩阵构建**：跨版本/平台的并行测试
- **市场**：数千个社区 Action

## 开发体验

### Rust 工具链

我们在整个开发工作流中优先选择**速度**，使用基于 Rust 的工具：

- **Biome**：一个工具完成代码检查和格式化，比 ESLint + Prettier 快 100 倍
- **uv**：Python 包管理器，比 pip/poetry 快 10-100 倍
- **Turbopack**：Next.js 打包器，比 Webpack 更快
- **Lightning CSS**：TailwindCSS v4 编译器，比 PostCSS 快 100 倍

### mise

- **多语言 monorepo 支持**：Node、Python、Flutter、Terraform — 不同生态，一个工具
- **项目本地版本**：`.mise.toml` 确保跨操作系统开发者入职时环境一致
- **任务运行器**：用统一的 `mise` 命令替代 Makefile、npm 脚本、shell 脚本
- **Rust 编写**：即时工具切换，无启动开销

### 多语言 Monorepo

- **单一仓库**：Web (TypeScript)、API (Python)、Mobile (Dart)、Infra (HCL) 集中在一处
- **有界上下文**：每种语言生态都限定在其目录内，防止交叉污染
- **原子变更**：单个 PR 中的前端 + 后端变更
- **统一工具**：所有应用使用相同的 `mise` 命令

## 权衡

| 选择 | 权衡 | 为什么接受 |
|--------|-----------|------------------|
| Next.js 而非 Remix/SvelteKit | 更大的包、更复杂 | 生态系统、React 19 兼容性 |
| Next.js 而非 Flutter Web | 与移动端代码库分离 | SEO、SSR、更小的包、Web 生态系统兼容性 |
| FastAPI 而非 Node.js | 两个运行时（Node + Python） | Python AI/ML 生态系统、可扩展性 |
| Flutter 而非 React Native | 更大的应用体积、自定义渲染 | 韩国 eGovFrame v5、灵活的版本控制 |

## 总结

这个技术栈优化了：

1. **开发者速度**：热重载、类型安全、自动生成客户端
2. **生产就绪**：托管服务、无服务器扩展、CI/CD
3. **团队可扩展性**：清晰的边界、共享工具、文档
4. **长期可维护性**：成熟的技术、活跃的社区
