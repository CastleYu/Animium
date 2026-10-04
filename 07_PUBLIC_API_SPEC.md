# 07 — Public API Specification

机器可读合同见 `contracts/openapi.yaml`。

## 1. General

Base path: `/v1`

所有响应：

- UTF-8 JSON
- timestamps RFC3339 UTC
- IDs 使用 UUID string
- list 使用 cursor pagination

错误格式：

```json
{
  "error": {
    "code": "INVALID_ARGUMENT",
    "message": "...",
    "request_id": "...",
    "details": {}
  }
}
```

## 2. Endpoints

### GET /v1/news

Filters:

- `source`
- `language`
- `anime_id`
- `published_from`
- `published_to`
- `q`
- `limit` (1..100, default 20)
- `cursor`

返回 canonical news，附 `sources[]` 和 `anime[]` 的轻量引用。

### GET /v1/news/{id}

返回单条 normalized news；不返回抓取全文。

### GET /v1/anime

Filters:

- `q`
- `season`
- `season_year`
- `status`
- `external_namespace`
- `external_id`

### GET /v1/anime/{id}

返回：

- canonical fields
- titles
- external_ids
- source provenance summary
- current schedule summary

### GET /v1/anime/{id}/news

按该 anime 返回新闻。

### GET /v1/schedule

Parameters:

- `from`
- `to`
- `timezone`（仅 presentation conversion；内部 UTC）
- `air_type`
- `anime_id`

### GET /v1/official/posts

Filters:

- `source`
- `anime_id`
- `published_from/to`

### GET /v1/sources

返回 source metadata + health：

- source_id
- kind
- access_method
- enabled
- health_status
- last_success_at
- last_error_at
- last_http_status

不暴露 secrets 或内部 legal notes。

### GET /health/live

只判断进程存活。

### GET /health/ready

检查 PostgreSQL；Redis 可根据部署模式决定是否是 hard dependency。上游 source 不应成为 readiness hard dependency。

## 3. Pagination

Cursor 是 opaque base64url token，内容至少绑定：

- sort value (`published_at`, `id`)
- query fingerprint

客户端不得解析 cursor。

## 4. Sorting

News 默认：`published_at DESC, id DESC`。

Anime 默认：`updated_at DESC, id DESC`，搜索时可按 relevance。

## 5. Caching

Public GET SHOULD 返回：

- `Cache-Control`
- `ETag`

数据更新频繁的 news/schedule max-age 短；anime detail 可稍长。

## 6. Rate Limit

MVP public API 建议每 IP：

- 60 req/min baseline
- 可通过部署层调整

返回标准 `429` 和 Retry-After。

## 7. Compatibility

`/v1` 内只允许 additive changes：

- 新 optional field
- 新 endpoint
- 新 enum value（客户端需按 unknown tolerant 设计）

字段删除、语义变化、类型变化 → `/v2` 或明确版本迁移。
