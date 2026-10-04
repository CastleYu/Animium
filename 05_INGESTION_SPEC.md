# 05 — Ingestion Specification

## 1. Adapter Contract

伪接口：

```ts
interface SourceAdapter<TCursor, TRaw, TNormalized> {
  sourceId: string;
  probe(ctx): Promise<ProbeResult>;
  fetch(ctx, cursor: TCursor | null): Promise<FetchResult<TRaw, TCursor>>;
  validate(raw: TRaw): ValidationResult;
  normalize(raw: TRaw): TNormalized[];
}
```

Adapter 不得直接写数据库。持久化由 ingestion service 统一完成。

## 2. ProbeResult

至少包含：

- reachable
- http_status
- content_type
- schema_ok
- auth_ok
- latency_ms
- checked_at
- detected_format
- notes

第一次 enable 前 probe 失败，source 保持 disabled。

## 3. RSS/Atom Fetch

MUST：

- Accept RSS/XML/Atom content types，并容忍部分站点错误标注为 text/xml/text/plain。
- 支持 gzip/br。
- timeout。
- ETag / If-None-Match。
- Last-Modified / If-Modified-Since。
- 304 视为成功但 0 新 item。
- GUID 不可信时使用 link + published timestamp hash。
- 所有 HTML entity / CDATA 正确解码。
- 不把 feed 内嵌全文直接暴露给 public DTO。

## 4. API Fetch

MUST：

- request timeout
- per-source concurrency
- status-aware retries
- response schema validation
- pagination upper bound
- request budget
- auth redaction

禁止 `while(nextPage)` 无边界全库扫描。每个 sync job 必须有明确 scope，例如“本季度”“最近更新”“指定 ID enrichment”。

## 5. Retry Policy

默认：

- network/5xx: 3 retries, exponential backoff + jitter
- 429: Retry-After 优先；无 header 时 source-specific default
- 401/403: 0 retry, mark auth_error
- 404: per endpoint semantic；单资源 404 不重试
- schema drift: 0 immediate retry，标记 degraded

## 6. Idempotency

### Source-native identity

优先级：

1. stable external ID/GUID
2. canonical URL
3. hash(source_id + normalized URL + published_at)

### Canonical news fingerprint

`sha256(normalized_title + primary_entity_hint + publication_day)` 仅作为候选去重，不直接作为唯一键。

## 7. Scheduling

建议默认频率：

- News RSS: 5 min
- Official Atom: 5 min
- AnimeSchedule timetable: 15 min
- Database enrichment: on-demand + daily refresh for active/current-season entities
- Kitsu/MAL/Bangumi broad refresh: 禁止无界全量轮询

所有频率可配置。

## 8. Backfill

MVP 默认只 backfill feed/API 当前可返回的数据，不主动爬历史网页。

News backfill 最大 90 天；超过范围需要单独 migration/job spec。

## 9. Source Health State Machine

- `healthy`
- `degraded`
- `rate_limited`
- `auth_error`
- `schema_drift`
- `disabled`

连续 5 次 transient failure → degraded；连续成功 3 次 → healthy。

## 10. Circuit Breaker

对同一 source：

- schema drift / 403 不继续高频打上游。
- 5xx 持续失败进入 open 15 min。
- rate-limited 按 reset 时间暂停。

## 11. Observability Fields

每次请求日志至少：

- source_id
- run_id
- endpoint_id
- attempt
- status
- latency_ms
- bytes_in
- items_parsed
- items_new
- items_duplicate
- error_code

不得记录 bearer token / client secret / full authorization header。
