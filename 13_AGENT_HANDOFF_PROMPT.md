# 13 — Agent Handoff Prompt

下面内容可直接作为开发 Agent 的首条任务提示词。

---

你现在接手一个“动漫资讯聚合 API”项目。你必须按 Spec-Driven Development 执行，不要先写功能再补规格。

项目规格目录是当前仓库的 `anime-aggregation-api-sdd/`（如果这些文件位于仓库根 `docs/`，按实际路径读取）。在写任何业务代码前，完整阅读以下文件，并把它们视为开发合同：

1. README.md
2. 00_SCOPE_AND_CONSTITUTION.md
3. 01_SOURCE_CATALOG.md
4. 02_PRODUCT_REQUIREMENTS.md
5. 03_SYSTEM_DESIGN.md
6. 04_DATA_MODEL.md
7. 05_INGESTION_SPEC.md
8. 06_ENTITY_MATCHING_AND_DEDUP.md
9. 07_PUBLIC_API_SPEC.md
10. 08_SOURCE_ADAPTER_SPECS.md
11. 09_SECURITY_LEGAL_COMPLIANCE.md
12. 10_TEST_AND_ACCEPTANCE.md
13. 11_OPERATIONS.md
14. 12_IMPLEMENTATION_PLAN.md
15. 14_RISK_REGISTER.md
16. adr/*
17. contracts/openapi.yaml
18. contracts/schema.sql
19. contracts/source-registry.example.yaml
20. contracts/.env.example

你的任务是实现 MVP。严格执行以下边界：

- 来源必须分为 NEWS、DATABASE、OFFICIAL。
- 第一阶段只实现 API 与 RSS/Atom。CRAWLER 来源即使有页面可抓，也不得实现、不得做隐藏 fallback。
- 不建立第三方新闻全文镜像；Public API 不返回第三方完整正文。
- 内部 `anime_id` 必须由本系统生成；AniList/MAL/Bangumi/Kitsu 等只能作为 external ID。
- 所有外部字段必须保留 provenance。
- 每个 source 有独立 enable/disable、poll rate、rate-limit、retry、circuit-breaker、health。
- AniList 是 restricted adapter：禁止全量同步/囤积。生产默认只有 legal gate 通过才能启用；如果条款与本服务实际用途存在疑问，保持 disabled，不要自行放宽。
- Jikan 默认 disabled，只能作为显式 fallback；不能替代 MAL 官方 API 成为主链路。
- YouTube 官方源只允许 allowlist 中经人工确认的 channel_id；不得根据频道名称猜“官方”。
- 不允许用轮换 IP、绕过 403/429、伪装浏览器等方式规避上游限制。

技术基线：TypeScript strict、Node.js LTS、Fastify、PostgreSQL、Redis/BullMQ、Zod、Vitest、Docker Compose。除非存在硬性 blocker，不要更换；若必须更换，先新增 ADR，说明原因、替代方案、影响，并同步修改规格。

按 `12_IMPLEMENTATION_PLAN.md` 的 Milestone 0 → 8 顺序工作。每完成一个 Milestone：

1. 运行测试；
2. 更新 requirement traceability；
3. 检查 OpenAPI/schema 是否 drift；
4. 输出本阶段完成项、未完成项、风险与下一阶段；
5. 不要把未验证的 source 标为 enabled。

开始编码前先完成这些前置动作：

- 创建 `docs/traceability.md`，把所有 `FR-*`/`NFR-*` 映射到设计章节与测试 ID。
- 执行 Source Probe（可写临时 CLI），对 P1 RSS/API endpoint 检查状态、content-type、解析是否成功、必要凭证是否存在，并生成 `docs/source-probe-report.md`。Probe 不通过的来源保持 disabled；不要改用爬虫。
- 生成首个 migration，并验证从空 PostgreSQL 执行成功。
- 验证 `contracts/openapi.yaml` 可被 OpenAPI validator 解析。

实现原则：

- Adapter 只负责 probe/fetch/validate/normalize，不直接写数据库。
- ingestion service 负责事务、幂等、cursor、health、provenance。
- 外部 HTTP 调用必须 timeout；429 尊重 Retry-After；401/403 不盲目重试；schema drift 要降级并留下有限诊断 fixture。
- RSS/Atom parser 必须禁用 XML 外部实体；Feed HTML excerpt 必须 sanitize/转纯文本并限制长度。
- 同一 feed 重跑 10 次不能增加重复记录。
- entity link 优先 external ID exact；模糊标题不确定时宁可 unmatched，也不要错绑。
- 上游冲突时保留证据，不做不可追溯覆盖。
- Redis 不能作为唯一持久状态；canonical data/cursor 必须在 PostgreSQL。

Public API 必须至少实现：

- GET /v1/news
- GET /v1/news/{id}
- GET /v1/anime
- GET /v1/anime/{id}
- GET /v1/anime/{id}/news
- GET /v1/schedule
- GET /v1/official/posts
- GET /v1/sources
- GET /health/live
- GET /health/ready

List endpoint 使用 opaque cursor pagination。错误响应、字段、查询参数以 `contracts/openapi.yaml` 为准。如果规格与机器合同存在冲突，不要自行猜；先指出冲突并按 SDD 修改规格/ADR 后再实现。

测试必须覆盖 `10_TEST_AND_ACCEPTANCE.md` 中所有 MUST 场景，尤其：幂等、429、单源隔离、schema drift、exact external ID link、同名歧义、XXE、防泄露 token、全文不外泄。

MVP 完成时交付：

- 可运行源码
- Docker Compose
- migrations
- seed/source registry
- OpenAPI
- unit/integration/E2E tests
- source probe report
- traceability matrix
- runbook
- `.env.example`
- README 的本地 Windows/Docker 启动方法
- release checklist

不要开展 Phase 2 的 HTML Crawler、Playwright、LLM 摘要/事件抽取、全文抓取、推荐系统或 Admin UI，除非 MVP 全部验收完成且用户明确追加范围。

现在先读取规格并给出：①你识别出的硬约束；②Milestone 0 的文件/目录计划；③发现的规格冲突（如有）。然后直接执行 Milestone 0，不需要再次询问用户确认。
