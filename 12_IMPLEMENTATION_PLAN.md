# 12 — Implementation Plan

以下顺序是 Agent 的默认执行计划。除非有 blocker，不要并行展开 Crawler/LLM 等范围外工作。

## Milestone 0 — Repository & Contract Lock

- [ ] 初始化 pnpm workspace
- [ ] TypeScript strict / lint / format / Vitest
- [ ] Docker Compose PostgreSQL + Redis 仅作为本地开发 profile
- [ ] 导入 `contracts/openapi.yaml`
- [ ] 导入 `contracts/schema.sql` 为 migration 0001
- [ ] 实现 config schema，覆盖 DB/Redis pool、timeout、TLS、namespace
- [ ] 建立 `createDatabase(config)` factory 骨架
- [ ] 建立 Queue/Cache connection factory 骨架
- [ ] 确认业务代码不得依赖 Docker hostname 或 localhost
- [ ] 建立独立 `db:migrate` 命令；应用启动不得自动 migration
- [ ] 建立 traceability table

DoD：空项目能 build/test；DB migration from empty 成功；同一 config schema 可表达本地与远程 PostgreSQL/Redis。

## Milestone 1 — Core Domain & Persistence

- [ ] source/source_endpoint/source_cursor/ingest_run repository
- [ ] news/anime/external-id/relations repositories
- [ ] official_post/schedule repositories
- [ ] transaction boundaries
- [ ] unique constraints tests
- [ ] repository 只接收共享 Database abstraction，不自行创建 Pool
- [ ] database pool/timeout/TLS config tests

DoD：fixture 可写入并幂等重放；替换数据库 endpoint 不需要改 repository 代码。

## Milestone 2 — Ingestion Framework

- [ ] Adapter interface
- [ ] scheduler + BullMQ
- [ ] Queue factory / Worker connection policy
- [ ] Cache abstraction 与 Redis implementation
- [ ] BullMQ `prefix` namespace；禁止 ioredis `keyPrefix`
- [ ] retries / backoff / circuit breaker
- [ ] source health state machine
- [ ] ETag/Last-Modified cursor
- [ ] structured logs
- [ ] API cache 故障降级策略
- [ ] Worker queue backend readiness

DoD：mock sources 能模拟 200/304/429/500/schema drift；Redis cache 故障不拖垮 API；queue backend 故障使 Worker not-ready。

## Milestone 3 — RSS/Atom

- [ ] Generic RSS/Atom parser
- [ ] Crunchyroll adapter config
- [ ] ANN adapter config
- [ ] MAL News config
- [ ] Anime Corner config
- [ ] Anime Herald config
- [ ] Tokyo Otaku Mode config
- [ ] YouTube official Atom adapter
- [ ] Source Probe CLI

DoD：至少 4 个 news feed + 3 个 official channel 通过 live probe；失败来源保持 disabled。

## Milestone 4 — Database APIs

- [ ] Bangumi v0 adapter
- [ ] MAL v2 adapter
- [ ] AnimeSchedule v3 adapter
- [ ] Kitsu adapter
- [ ] AniList restricted adapter + legal gate
- [ ] AnimeThemes optional adapter

DoD：各 adapter contract fixture + live smoke；没有全库循环。

## Milestone 5 — Entity Matching & Dedup

- [ ] normalized titles
- [ ] external ID exact match
- [ ] title/year/format candidate scoring
- [ ] same-source dedupe
- [ ] cross-source high confidence clustering
- [ ] ambiguous candidate persistence

DoD：`IT-ENTITY-*` + `UT-DEDUPE-*` passed。

## Milestone 6 — Public API

- [ ] news endpoints
- [ ] anime endpoints
- [ ] schedule endpoint
- [ ] official posts
- [ ] sources/health
- [ ] API/Worker 分离 readiness
- [ ] cursor pagination
- [ ] OpenAPI response validation
- [ ] ETag/cache headers

DoD：E2E tests pass，spec 与实现无 drift。

## Milestone 7 — Security & Ops

- [ ] XML XXE hardening
- [ ] HTML excerpt sanitize
- [ ] secret/TLS material redaction
- [ ] public API rate limit
- [ ] metrics
- [ ] PostgreSQL backup/restore docs
- [ ] Redis queue durability/recovery docs
- [ ] production Docker config
- [ ] remote PostgreSQL/Redis TLS deployment example
- [ ] verify DB/Redis ports are not exposed publicly in single-host example

## Milestone 8 — Release Candidate

- [ ] source probe report
- [ ] legal gate report
- [ ] traceability 100% MUST
- [ ] test report
- [ ] migration clean-room test
- [ ] local Compose infrastructure smoke
- [ ] external-endpoint PostgreSQL/Redis smoke using same build artifact
- [ ] operator runbook validation
- [ ] changelog / release notes

## Explicitly Deferred

- HTML crawlers
- Playwright/browser scraping
- X/Twitter API
- article full-text extraction
- LLM summaries/event extraction
- recommendation/ranking fusion
- admin UI
