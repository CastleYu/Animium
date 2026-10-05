# 14 — Risk Register

| ID | 风险 | 概率 | 影响 | 缓解 |
|---|---|---:|---:|---|
| R-001 | RSS endpoint 被删除/改格式 | 中 | 中 | probe + contract fixture + source disable |
| R-002 | 第三方 API rate limit/封禁 | 中 | 高 | per-source budget、backoff、缓存、无全量同步 |
| R-003 | AniList 条款与商业 API 聚合模式冲突 | 中 | 高 | legal gate、默认 restricted、可完全禁用 |
| R-004 | 新闻全文转载版权风险 | 高 | 高 | 不做全文 API；只输出 metadata/excerpt/link |
| R-005 | 同名作品错误合并 | 中 | 高 | external ID first、year/format、ambiguous 不自动合并 |
| R-006 | sequel/season 标题造成错误匹配 | 高 | 中 | season token parser + high threshold |
| R-007 | 上游字段冲突 | 高 | 中 | provenance + trust tiers + conflicted flag |
| R-008 | XML XXE/恶意 feed | 低 | 高 | 禁用 external entity + payload size limit |
| R-009 | queue backlog 导致新闻延迟 | 中 | 中 | metrics、worker scaling、per-source isolation |
| R-010 | feed item GUID 变化造成重复 | 中 | 中 | URL hash + canonical fingerprint |
| R-011 | MAL/Kitsu/AnimeSchedule API 变更 | 中 | 中 | schema validation + adapter contract |
| R-012 | Official YouTube channel 冒名 | 低 | 高 | channel allowlist +人工 verification evidence |
| R-013 | 依赖 Jikan 导致间接 MAL 抓取风险 | 中 | 中 | default disabled、仅 fallback |
| R-014 | 把 Redis 当 canonical 持久层导致数据/游标丢失 | 低 | 高 | canonical/cursor state 放 PostgreSQL；Redis 只做 operational state |
| R-015 | “自动 fallback 到爬虫”突破范围/合规边界 | 中 | 高 | 架构上禁止，CRAWLER source 在 P1 不可执行 |
| R-016 | 业务代码写死 Docker hostname/localhost，迁移服务器时需要改代码 | 中 | 高 | config factory + portability integration test + ADR-0007 |
| R-017 | 每个 repository/handler 自建 PG Pool 导致连接爆炸 | 中 | 高 | shared Database factory/pool + code review/test |
| R-018 | 多 replica 启动时自动 migration 造成锁竞争/失败 | 中 | 高 | migration 独立 one-shot job，startup 禁止 migration |
| R-019 | Redis 内存淘汰 BullMQ key 导致任务状态损坏 | 中 | 高 | queue Redis 使用 no-eviction 等效策略 + capacity alert |
| R-020 | Redis 无持久化导致 waiting/delayed/retry jobs 丢失 | 中 | 中 | production queue persistence + 可从 PG cursor/schedule 重建任务 |
| R-021 | API 把 cache Redis 当硬依赖导致不必要全站 503 | 中 | 中 | cache failure fallback PostgreSQL + readiness 分层 |
| R-022 | 远程 PG/Redis 凭证或 CA 被提交/日志泄露 | 低 | 高 | env/Secret/file mount + log redaction + security test |
| R-023 | TLS/网络配置差异导致本地通过、服务器失败 | 中 | 中 | remote endpoint smoke + TLS config contract + runbook |

## Open Questions（不阻塞开发骨架）

1. 服务最终是否商业化？若是，必须在生产启用 AniList 前完成许可判断。
2. Public API 是否需要 API key/账号？MVP 可匿名限流，商业化前再加 key。
3. 是否需要中文机器翻译？不在 MVP。
4. 是否需要新闻“事件化”？建议 P2，在稳定采集和 entity link 后再做。
5. 是否需要历史 backfill >90 天？需要单独成本与版权评估。
6. 最终 PostgreSQL/Redis 使用自建还是托管不需要在 MVP 前锁定；实现必须保持可替换。
