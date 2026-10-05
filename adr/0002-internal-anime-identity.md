# ADR-0002 — 使用内部 Anime ID，不绑定任何第三方数据库主键

- Status: Accepted
- Date: 2026-10-05

## Context

AniList、MyAnimeList、Bangumi、Kitsu、AnimeSchedule 等数据库的 ID 都属于各自外部命名空间，可能发生删除、合并、权限或接口变化。把任一外部 ID 作为系统主键会导致上游变化直接污染内部数据模型。

## Decision

系统生成自己的 UUID 作为 `anime.id`。

所有第三方 ID 存储为 `anime_external_id(namespace, external_id)`，并建立唯一约束。

实体匹配优先级：

1. external ID exact match
2. 多源 cross-reference
3. exact normalized alias + year/format
4. fuzzy candidate

模糊匹配有歧义时保持 unmatched 或 candidate，不强制合并。

## Consequences

- 上游数据库可独立启停。
- 可保留跨库映射和 provenance。
- 需要维护实体匹配与合并逻辑，但避免了长期主键锁定。
