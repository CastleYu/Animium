# ADR-0005 — AniList 仅作为受限按需 Enrichment Adapter

- Status: Accepted
- Date: 2026-10-05

## Context

AniList 官方 API Terms 对 hoarding、mass collection、作为备份/存储服务、竞争性用途及部分商业场景有明确限制。

## Decision

AniList Adapter：

- 默认 `enabled=false`。
- `legal_status=review`。
- 只允许按已知 ID/title 做按需 enrichment。
- 不运行全库同步。
- 不长期保存完整 AniList 镜像。
- 缓存采用短 TTL。
- 生产环境只有 legal gate 明确通过后才能启用。

## Consequences

- AniList 不成为核心可用性的单点依赖。
- 需要依靠 Bangumi/MAL/Kitsu/AnimeSchedule 等多源组合。
