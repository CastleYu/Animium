# 02 — Product Requirements

## 1. 用户与使用场景

### API Consumer
需要通过一个统一 API 获取动漫资讯、关联作品、放送表与官方发布，不希望理解每个上游格式。

### Operator
需要知道哪个来源失败、为什么失败、最近一次成功时间、是否触发限流/熔断。

### Maintainer
需要添加新来源时只实现 Adapter，不改核心领域模型。

## 2. Functional Requirements

### Source & Ingestion

- `FR-SRC-001` 系统 MUST 将来源分为 NEWS、DATABASE、OFFICIAL。
- `FR-SRC-002` 系统 MUST 将接入方式标为 API、RSS、CRAWLER。
- `FR-SRC-003` MVP MUST 拒绝执行 `access_method=CRAWLER` 的来源。
- `FR-SRC-004` 每个来源 MUST 可单独 enable/disable。
- `FR-SRC-005` 每次采集 MUST 记录 ingest run、HTTP 状态、耗时、item count、错误。
- `FR-SRC-006` RSS/API Adapter MUST 支持幂等重复采集。
- `FR-SRC-007` 支持 ETag/Last-Modified 的来源 SHOULD 使用条件请求。
- `FR-SRC-008` 遇到 429 MUST 尊重 Retry-After 或来源 rate-limit reset。
- `FR-SRC-009` 单个来源失败 MUST NOT 阻塞其他来源。
- `FR-SRC-010` Source Probe MUST 在首次启用与部署后运行。

### News

- `FR-NEWS-001` MUST 标准化 title、url、published_at、source、language。
- `FR-NEWS-002` SHOULD 保存 feed 自带 excerpt，但 MUST 设长度上限。
- `FR-NEWS-003` MUST 生成稳定 dedupe key。
- `FR-NEWS-004` MUST 能把 news 关联到 0..N 个 anime。
- `FR-NEWS-005` MUST 支持按 source、language、anime_id、时间范围过滤。
- `FR-NEWS-006` MUST 保留原始来源 URL 与 attribution。
- `FR-NEWS-007` MUST NOT 默认向 API 输出第三方全文正文。

### Anime Metadata

- `FR-ANI-001` MUST 使用内部稳定 `anime_id`。
- `FR-ANI-002` MUST 支持 AniList/MAL/Bangumi/Kitsu/AnimeSchedule 等 external ID 映射。
- `FR-ANI-003` MUST 支持多语言 title/alias。
- `FR-ANI-004` MUST 保存字段 provenance 或至少 source priority。
- `FR-ANI-005` 不同源冲突 MUST NOT 静默覆盖；必须可追溯。
- `FR-ANI-006` MUST 支持按 title/external id 查询 anime。
- `FR-ANI-007` MUST 支持当前季度/放送表查询。

### Official

- `FR-OFF-001` MUST 支持 YouTube Atom channel feed。
- `FR-OFF-002` 只有 allowlist 中的已验证官方 channel 才能启用。
- `FR-OFF-003` MUST 保存 channel_id、video_id、published_at、watch_url。
- `FR-OFF-004` SHOULD 将官方发布与 anime 关联。
- `FR-OFF-005` 官方信息在事实冲突排序中拥有更高 evidence weight，但 MUST 保留其他来源。

### Public API

- `FR-API-001` MUST 以 `/v1` 作为稳定版本前缀。
- `FR-API-002` list endpoint MUST 使用 cursor pagination。
- `FR-API-003` MUST 提供 `/v1/news`。
- `FR-API-004` MUST 提供 `/v1/anime` 与 `/v1/anime/{id}`。
- `FR-API-005` MUST 提供 `/v1/anime/{id}/news`。
- `FR-API-006` MUST 提供 `/v1/schedule`。
- `FR-API-007` MUST 提供 `/v1/official/posts`。
- `FR-API-008` MUST 提供 `/v1/sources`。
- `FR-API-009` MUST 提供 `/health/live` 与 `/health/ready`。
- `FR-API-010` API errors MUST 采用统一 error envelope。

## 3. Non-Functional Requirements

- `NFR-001` 单个公开 GET endpoint 正常缓存命中时 p95 SHOULD < 300 ms。
- `NFR-002` ingestion 至 API 可见的目标延迟：RSS <= 10 min；API schedule <= 30 min；official Atom <= 10 min。
- `NFR-003` 所有数据库写入 MUST 有 unique/index 保障幂等。
- `NFR-004` 所有外部 HTTP 调用 MUST 有 connect/read timeout。
- `NFR-005` MUST 有 per-source concurrency limit。
- `NFR-006` 日志 MUST 是结构化日志，包含 `run_id` / `source_id` / `request_id`。
- `NFR-007` 凭证 MUST 只来自 secret/env，不进入源码或日志。
- `NFR-008` 所有时间内部存 UTC；API 输出 RFC3339。
- `NFR-009` 数据库 migration MUST 可重复执行并有版本号。
- `NFR-010` 必须可在 Windows + Docker Desktop 开发，在 Linux container 生产部署。
- `NFR-011` Source Adapter contract test MUST 可使用 fixture，不要求 CI 每次依赖真实互联网。
- `NFR-012` 外部数据字段必须能追踪 `source_id` 与 external URL/ID。
- `NFR-013` 应用 MUST 通过配置连接 PostgreSQL 与 Redis，不得依赖 `localhost`、Docker service name、固定 IP 或特定云厂商 endpoint。
- `NFR-014` 同一应用镜像 MUST 能通过环境变量切换本地 Compose、同机部署、独立数据库服务器和托管 PostgreSQL/Redis；切换部署形式不得要求修改业务代码。
- `NFR-015` PostgreSQL 连接 MUST 通过统一 Database Factory/Pool 建立，并支持连接池、连接超时、空闲超时、statement timeout 与可选 TLS。
- `NFR-016` Redis/BullMQ 连接 MUST 通过统一 Queue/Cache 连接层建立；业务模块不得直接创建 Redis client 或依赖 Redis 私有 key 结构。
- `NFR-017` Queue 与 Cache MUST 在逻辑上分离，即使部署时共享同一个 Redis；队列 key 使用 BullMQ 的 `prefix` 机制，不得使用 ioredis `keyPrefix`。
- `NFR-018` PostgreSQL migration MUST 作为显式部署步骤运行，不得由每个 API/Worker replica 在启动时竞争执行。
- `NFR-019` Redis MUST NOT 成为 canonical datastore；生产队列 Redis SHOULD 启用持久化并使用禁止淘汰队列 key 的内存策略。
- `NFR-020` Readiness MUST 按进程职责区分：API 以 PostgreSQL/config 为硬依赖，纯缓存 Redis 故障不应强制 API 503；Worker 以 PostgreSQL 与 Queue backend 为硬依赖。

## 4. MVP Success Metrics

- >= 4 个 NEWS RSS 来源通过生产 source probe。
- >= 4 个 DATABASE API 来源可运行（其中至少包含 Bangumi + MAL 或 AnimeSchedule）。
- >= 3 个官方 YouTube channel feed 接入。
- 24h 内重复新闻率（用户可见） < 3%。
- 同一条 feed item 重跑 10 次，数据库记录数不增长。
- source failure 不导致 API 不可用。
- 本地 Compose 与“外部 PostgreSQL + 外部 Redis”两种配置均通过 integration smoke，应用代码不发生条件分支修改。
- 所有 MUST requirements 验收通过。

## 5. Requirement Traceability

实现时建立 `docs/traceability.md`，格式：

| Requirement | Design section | Test ID | Status |
|---|---|---|---|
| FR-SRC-006 | 05 §6 | IT-INGEST-001 | pending |
| NFR-014 | 03 §5 | IT-INFRA-001 | pending |

Agent 不得在没有更新 traceability 的情况下把 requirement 标记为 done。
