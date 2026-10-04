# 04 — Data Model

完整 DDL 见 `contracts/schema.sql`。

## 1. Core Entities

### source
描述逻辑来源。

关键字段：

- `id` text PK，例如 `news_ann_us`
- `kind`: NEWS / DATABASE / OFFICIAL
- `access_method`: API / RSS / CRAWLER
- `trust_tier`: T0..T4
- `enabled`
- `legal_status`: approved / review / blocked
- `poll_interval_seconds`

### source_endpoint
同一 source 可有多个 endpoint。

- url
- endpoint_type
- auth_mode
- locale
- config JSONB

### ingest_run
每次采集执行记录。

- run_id UUID
- source_id
- started_at / finished_at
- status
- http_status
- fetched_count / accepted_count / duplicate_count / error_count
- error_code / error_message

### source_cursor
保存 ETag、Last-Modified、next cursor、last external timestamp 等。

---

## 2. News

### news_article
标准化资讯条目。

- `id` UUID
- `title`
- `canonical_url`
- `language`
- `excerpt` nullable
- `published_at`
- `updated_at`
- `first_seen_at`
- `content_fingerprint`

### news_source_item
将 canonical news 与某个来源 item 绑定。

- `news_id`
- `source_id`
- `external_id`
- `source_url`
- `raw_hash`
- `source_published_at`

一条 canonical news 可以有多个 source item，用于跨站去重。

---

## 3. Anime

### anime
内部实体。

- `id` UUID
- `canonical_title`
- `original_title`
- `format`
- `status`
- `start_date`
- `end_date`
- `season`
- `season_year`
- `adult_flag`
- `created_at / updated_at`

### anime_title

- `anime_id`
- `title`
- `language`
- `script`
- `title_type`: canonical / official / synonym / romaji / translated
- `source_id`

### anime_external_id

- `anime_id`
- `namespace`: anilist / mal / bangumi / kitsu / animeschedule / anidb / animethemes ...
- `external_id`
- `source_id`
- unique(namespace, external_id)

### anime_provenance
按字段保存来源：

- `anime_id`
- `field_name`
- `source_id`
- `source_value` JSONB
- `confidence`
- `observed_at`

canonical 字段变化时不可删除旧证据；可以通过 latest/materialized view 得到当前值。

---

## 4. Relations

### news_anime

- `news_id`
- `anime_id`
- `relation_type`: explicit_id / exact_title / fuzzy_title / manual
- `confidence`
- `matched_title`

### official_post

- `id`
- `source_id`
- `external_id`（YouTube video ID）
- `channel_id`
- `title`
- `url`
- `published_at`
- `updated_at`
- `content_fingerprint`

### official_post_anime
与 `news_anime` 相同逻辑。

### schedule_entry

- anime_id
- source_id
- air_type: raw / sub / dub / unknown
- episode_number nullable
- starts_at
- timezone/source_timezone
- status

---

## 5. Identity Rules

内部 anime ID 不随任何第三方删除/改名而变化。

创建新 anime 的优先条件：

1. 已知 external ID 与现有映射完全命中 → 使用现有。
2. 多源 external ID cross-reference 指向同一对象 → 合并。
3. title + year + format 高置信匹配 → 建候选关系；超过阈值才自动合并。
4. 不确定 → 创建 provisional entity 或保留 unmatched，不得强行合并。

## 6. Deletion/Correction

上游 item 消失不立即硬删除。使用：

- `is_active`
- `last_seen_at`
- `deleted_at`（内部确认后）

MVP 只软删除。

## 7. Raw Payload Policy

为了调试 parser drift，可在 `ingest_raw_sample` 保存受限 payload：

- 默认保留 <= 7 天。
- 最多保存有限样本而不是全量历史。
- 对 RSS full-body 做截断或不保存正文。
- 敏感 header/token 永不落库。
