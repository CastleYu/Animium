# 动漫资讯聚合 API — SDD 前期交付包

版本：0.1.0  
研究/冻结日期：2026-10-04  
方法：Spec-Driven Development（规格驱动开发）

## 1. 目标

构建一个聚合多个动漫资讯站、动漫数据库和动画官方发布渠道的统一 API。第一阶段只实现有公开 API、RSS/Atom 等结构化接口的来源；需要 HTML 抓取的来源仅登记、评估，不进入首版实现。

核心原则：

- 将 **资讯源（News）**、**数据库源（Metadata/Database）**、**动画官方源（Official）** 分开建模。
- 将接入方式分为 **API**、**RSS/Atom**、**Crawler** 三类；第一阶段只启用 API 与 RSS/Atom。
- 不把任何第三方数据库当作内部主键；系统生成自己的 `anime_id`，外部 ID 只是映射。
- 不做第三方站点全文镜像。默认仅保存聚合所需字段、来源 URL、必要摘要/Feed excerpt 与数据血缘。
- 每个来源必须有独立 Adapter、限流、缓存、重试、熔断、健康状态和可禁用开关。
- 对来源条款、商业许可、转载版权采取“默认保守”策略。
- PostgreSQL 与 Redis 视为可远程部署的基础设施依赖；Docker Compose 仅是本地开发/可选单机部署方式。
- 同一应用构建产物必须通过环境变量/Secret 支持本地、单机、独立服务器或托管 PostgreSQL/Redis，不得因部署拓扑变化修改业务代码。

## 2. 第一阶段交付范围（MVP）

### 资讯源

优先实现：

1. Crunchyroll News RSS
2. Anime News Network RSS
3. MyAnimeList News RSS
4. Anime Corner RSS
5. Anime Herald RSS
6. Tokyo Otaku Mode News RSS

后 4 个必须经过上线前 Source Probe；如果 HTTP 状态、格式或站点条款不满足条件，应保持 disabled，而不是临时切换为 HTML 抓取。

### 数据库源

优先实现：

1. Bangumi Public API v0
2. MyAnimeList API v2
3. AnimeSchedule API v3
4. Kitsu JSON:API
5. AniList GraphQL（受条款约束，默认只做按需 enrichment，不得全量镜像）
6. AnimeThemes API（P1.1 enrichment，可在基础 MVP 之后启用）

Jikan 仅作为非官方 MAL fallback 候选，不作为生产主依赖。

### 动画官方源

第一阶段通过 YouTube 官方频道 Atom Feed 统一接入。Adapter 使用 Google 官方文档所描述的：

`https://www.youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID`

具体频道通过 allowlist 配置；只接入已人工确认属于制作/发行/版权方的频道。作品官网、制作公司新闻页等 HTML 来源进入 Phase 2 Crawler。

## 3. 文档阅读顺序

1. `00_SCOPE_AND_CONSTITUTION.md`
2. `01_SOURCE_CATALOG.md`
3. `02_PRODUCT_REQUIREMENTS.md`
4. `03_SYSTEM_DESIGN.md`
5. `04_DATA_MODEL.md`
6. `05_INGESTION_SPEC.md`
7. `06_ENTITY_MATCHING_AND_DEDUP.md`
8. `07_PUBLIC_API_SPEC.md`
9. `08_SOURCE_ADAPTER_SPECS.md`
10. `09_SECURITY_LEGAL_COMPLIANCE.md`
11. `10_TEST_AND_ACCEPTANCE.md`
12. `11_OPERATIONS.md`
13. `12_IMPLEMENTATION_PLAN.md`
14. `13_AGENT_HANDOFF_PROMPT.md`
15. `14_RISK_REGISTER.md`
16. `15_RESEARCH_NOTES.md`
17. `adr/*`
18. `contracts/openapi.yaml`
19. `contracts/schema.sql`
20. `contracts/source-registry.example.yaml`
21. `contracts/.env.example`

## 4. 规格状态

- `MUST`：开发 Agent 不得自行省略。
- `SHOULD`：除非存在明确技术阻碍，否则实现。
- `MAY`：可延期。
- 所有设计变更必须新增 ADR，并同步修改相关 Requirement、Acceptance Test 与 OpenAPI/Schema。

## 5. 技术基线

首选实现：

- TypeScript（strict）
- Node.js LTS
- Fastify
- PostgreSQL 16+
- Redis + BullMQ
- Zod
- Drizzle ORM（或纯 SQL migration；若改 ORM 必须 ADR）
- Vitest
- Docker Compose（本地开发 profile）

Windows 开发环境以 Docker Desktop + WSL2 为推荐路径；应用容器按 Linux 生产环境设计。

### 基础设施部署约束

应用不得假设 PostgreSQL/Redis 与自身处于同一个 Docker network。所有连接信息通过 `contracts/.env.example` 中定义的配置注入。

支持的目标形式：

```text
Local Compose
  ├─ PostgreSQL
  └─ Redis

Single Server
  ├─ App
  ├─ PostgreSQL
  └─ Redis

Split / Managed
  App Server
    ├─ remote/managed PostgreSQL
    └─ remote/managed Redis
```

切换部署形式不得修改 repository、service、handler、adapter 等业务代码。

## 6. 关键外部文档

- AniList API Docs: https://docs.anilist.co/
- AniList Terms of Use: https://docs.anilist.co/guide/terms-of-use
- Bangumi API: https://bangumi.github.io/api/
- Bangumi API repository/docs: https://github.com/bangumi/api
- MyAnimeList API v2: https://myanimelist.net/apiconfig/references/api/v2
- Kitsu API: https://kitsu.docs.apiary.io/
- AnimeSchedule API v3: https://animeschedule.net/api/v3/documentation
- AnimeSchedule API Terms: https://animeschedule.net/api-terms-of-use
- Jikan API: https://docs.api.jikan.moe/
- AnimeThemes API: https://api-docs.animethemes.moe/
- YouTube push/Atom feed: https://developers.google.com/youtube/v3/guides/push_notifications

## 7. Definition of Ready

开发 Agent 开始编码前，必须确认：

- 已完整读取本目录所有 MUST 规格。
- 已生成 source probe 报告并确认实际可访问的 Phase 1 endpoints。
- 已准备 MAL Client ID、AnimeSchedule application token（如果启用）、Bangumi UA；所有密钥只进入环境变量。
- 已确认 AniList 的实际使用方式满足条款；若无法确认，默认禁用 AniList adapter。
- 已锁定数据库 migration 与 OpenAPI contract。
- 已理解 ADR-0007：PostgreSQL/Redis 部署拓扑不得泄漏进业务层。
- 已定义独立 migration 命令以及 Database/Queue/Cache factory 边界。

## 8. Definition of Done

MVP 完成的最低条件：

- 所有启用来源能稳定采集、幂等写入、记录血缘。
- 同一来源重复抓取不产生重复数据。
- 至少完成外部 ID 精确映射 + 标题/年份候选匹配。
- API 的响应与 `contracts/openapi.yaml` 一致。
- 所有 MUST requirement 有自动化测试或明确的人工验收步骤。
- 源不可用时不会拖垮全局任务队列。
- `/v1/sources` 能展示来源健康度、最后成功时间、是否启用。
- 不对外提供第三方正文全文镜像。
- 同一构建产物在本地 Compose 与外部 PostgreSQL/Redis endpoint 配置下均通过基础设施 smoke test。
- API cache Redis 故障时可降级访问 PostgreSQL；Worker queue backend 故障时正确进入 not-ready。
- migration 通过独立部署命令执行，API/Worker 启动不自动竞争 migration。
