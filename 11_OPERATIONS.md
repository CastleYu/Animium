# 11 — Operations

## 1. Deployment Topology

Docker Compose / container platform:

- `api` replicas >=1
- `worker` replicas >=1
- PostgreSQL
- Redis
- reverse proxy / ingress

Local Windows：Docker Desktop + WSL2。

## 2. Health

### Liveness
进程能处理 event loop。

### Readiness
- PostgreSQL reachable
- migration version compatible
- 必要配置加载成功

上游新闻站不可用不影响 API readiness。

## 3. Metrics

建议 Prometheus-compatible metrics：

- `source_fetch_total{source,status}`
- `source_fetch_latency_seconds`
- `source_items_fetched_total`
- `source_items_inserted_total`
- `source_schema_drift_total`
- `queue_depth`
- `job_retry_total`
- `api_requests_total`
- `api_latency_seconds`
- `entity_match_confidence_bucket`

## 4. Alerts

- source 30 min 无成功（5 min source）
- auth_error immediate
- schema_drift immediate
- queue depth 持续上升
- DB connection saturation
- disk > 80%
- API 5xx rate > threshold

## 5. Backup

- PostgreSQL daily logical/managed snapshot
- migration files version controlled
- Redis 不作为唯一持久数据来源，可重建

恢复目标：

- RPO <= 24h（MVP）
- RTO <= 4h（MVP）

## 6. Source Runbook

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

## 7. Config Management

Source Registry 使用 YAML + DB runtime state：

- YAML: code-reviewed declarative definition
- DB: last health/cursor/runtime counters

生产 source enable 变化 SHOULD 通过 code review/config deployment，MVP 不必做 admin web UI。
