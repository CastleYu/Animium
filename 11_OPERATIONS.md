# 11 — Operations

## 1. Deployment Topology

PostgreSQL 与 Redis 视为网络基础设施依赖，而不是“必须由项目 Compose 创建的服务”。

同一应用镜像支持三种部署形式：

### A. Local development

```text
Docker Desktop / Compose
├─ api
├─ worker
├─ postgres
└─ redis
```

Windows 推荐 Docker Desktop + WSL2。

### B. Single-server production

```text
Server
├─ reverse proxy / ingress
├─ api
├─ worker
├─ postgres + persistent volume
└─ redis + persistence
```

5432/6379 不应直接暴露公网。

### C. Split / managed production

```text
Internet
  │
 HTTPS
  │
Reverse Proxy
  │
  ├─ api
  └─ worker (no public listener)
       │
       ├─ private network / TLS → PostgreSQL or managed PostgreSQL
       └─ private network / TLS → Redis or managed Redis
```

应用在 A/B/C 之间迁移只修改环境变量/Secret。

## 2. PostgreSQL Runtime

PostgreSQL 16+。

应用 MUST 使用统一连接池，不允许 repository/handler 单独创建数据库连接。

配置：

- `DATABASE_URL`
- `DATABASE_POOL_MAX`
- `DATABASE_CONNECT_TIMEOUT_MS`
- `DATABASE_IDLE_TIMEOUT_MS`
- `DATABASE_STATEMENT_TIMEOUT_MS`
- `DATABASE_SSL_MODE`
- `DATABASE_SSL_CA_PATH`

跨不可信网络时必须启用 TLS，并按部署平台通过 Secret/file mount 提供 CA；不得把证书内容写入仓库。

Migration 必须作为独立部署任务运行，完成后再启动/滚动 API 和 Worker；应用启动不自动运行 migration。

## 3. Redis / BullMQ Runtime

Redis 承担 operational state：

- BullMQ queue/job/retry/delayed state
- API transient cache
- coordination

PostgreSQL 仍是 canonical datastore。

Queue 与 Cache 必须使用不同逻辑 namespace。BullMQ 使用自身 `prefix` 参数，不使用 ioredis `keyPrefix`。

生产 queue Redis SHOULD：

- 启用持久化（自建时建议 AOF）
- 使用适合队列的持久化/恢复策略
- 配置 `maxmemory-policy=noeviction` 或等效的不淘汰队列 key 策略
- 不将 `FLUSHDB`、`KEYS *` 作为正常应用逻辑

远程 Redis 支持 `redis://` 或 `rediss://`，TLS/CA 通过配置与 Secret 注入。

## 4. Health

### Liveness

只判断当前进程/event loop 存活。

### API Readiness

硬依赖：

- PostgreSQL reachable
- migration version compatible
- 必要 config 合法

Redis 若仅用于 API cache，则 cache 故障不应使 API 整体 not ready；应降级为直接读 PostgreSQL，并记录 degraded metric/log。

### Worker Readiness

硬依赖：

- PostgreSQL reachable
- queue backend reachable
- 必要 config 合法

上游新闻/API source 不应成为 API 或 Worker 的全局 readiness hard dependency。

## 5. Metrics

建议 Prometheus-compatible metrics：

- `source_fetch_total{source,status}`
- `source_fetch_latency_seconds`
- `source_items_fetched_total`
- `source_items_inserted_total`
- `source_schema_drift_total`
- `queue_depth`
- `job_retry_total`
- `queue_backend_available`
- `cache_backend_available`
- `db_pool_active`
- `db_pool_waiting`
- `api_requests_total`
- `api_latency_seconds`
- `entity_match_confidence_bucket`

## 6. Alerts

- source 30 min 无成功（5 min source）
- auth_error immediate
- schema_drift immediate
- queue depth 持续上升
- queue backend unavailable
- DB connection saturation
- disk > 80%
- API 5xx rate > threshold

## 7. Backup & Recovery

### PostgreSQL

- daily logical/managed snapshot
- migration files version controlled
- restore smoke test

### Redis

Redis 不是 canonical datastore，但 queue state 具有运行价值。生产 SHOULD 启用持久化或托管服务的等效耐久能力。

Redis 丢失后的恢复策略必须假设：

- canonical anime/news 数据仍在 PostgreSQL
- waiting/delayed/retry jobs 可能需要从 source schedule/cursor 重新生成
- source cursor 不能只保存在 Redis

恢复目标：

- PostgreSQL RPO <= 24h（MVP）
- PostgreSQL RTO <= 4h（MVP）

## 8. Migration / Deployment Order

推荐：

```text
1. provision/update secrets
2. verify PostgreSQL/Redis connectivity
3. run db:migrate as one-shot job
4. start/roll worker
5. start/roll api
6. run readiness checks
7. run source probe smoke
```

不得让多个 replica 在进程启动时同时执行 migration。

## 9. Source Runbook

### 429
- inspect Retry-After/rate headers
- reduce concurrency/polling
- do not rotate IP to circumvent limit

### 403
- verify auth/UA/terms
- disable source if policy change suspected
- do not switch to stealth crawler

### XML parse failure
- save capped diagnostic fixture
- mark schema_drift
- update adapter test first, then parser

### duplicated news spike
- inspect source GUID changes
- inspect URL canonicalization
- inspect cross-source dedupe threshold

## 10. Infrastructure Runbook

### PostgreSQL unreachable

- verify DNS/private network/firewall
- verify TLS/CA
- inspect pool saturation
- do not switch application code to a hardcoded fallback host

### Redis queue backend unreachable

- API may remain available if database is healthy
- Worker readiness fails
- enqueue path returns controlled error or bounded retry
- Worker reconnects according to background retry policy
- do not bypass queue by writing ad-hoc job state into PostgreSQL without ADR

### Cache backend unreachable

- disable/bypass cache path
- continue API reads from PostgreSQL where safe
- record degraded metric

## 11. Config Management

Source Registry 使用 YAML + DB runtime state：

- YAML: code-reviewed declarative definition
- DB: last health/cursor/runtime counters

Infrastructure connection data 只来自 env/Secret，不写进 Source Registry。

生产 source enable 变化 SHOULD 通过 code review/config deployment，MVP 不必做 admin web UI。
