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
| R-014 | 把 Redis 当持久层导致状态丢失 | 低 | 中 | canonical/cursor state 放 PostgreSQL，Redis 可重建 |
| R-015 | “自动 fallback 到爬虫”突破范围/合规边界 | 中 | 高 | 架构上禁止，CRAWLER source 在 P1 不可执行 |

## Open Questions（不阻塞开发骨架）

1. 服务最终是否商业化？若是，必须在生产启用 AniList 前完成许可判断。
2. Public API 是否需要 API key/账号？MVP 可匿名限流，商业化前再加 key。
3. 是否需要中文机器翻译？不在 MVP。
4. 是否需要新闻“事件化”？建议 P2，在稳定采集和 entity link 后再做。
5. 是否需要历史 backfill >90 天？需要单独成本与版权评估。
