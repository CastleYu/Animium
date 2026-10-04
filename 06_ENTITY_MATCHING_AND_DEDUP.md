# 06 — Entity Matching & Deduplication

## 1. 目标

解决两个不同问题：

1. `Entity Matching`：一条资讯说的是哪部 anime。
2. `News Dedup`：多个站点是否在报道同一个事实/事件。

两者不可混为一个 hash 问题。

## 2. Anime Entity Matching

### Level 1 — External ID Exact

最高置信：

- upstream 直接带 MAL/AniList/Bangumi/Kitsu ID。
- AnimeSchedule 返回其网站字段中的外部 ID。
- 已存在 source-specific external mapping。

置信度 1.0。

### Level 2 — Exact title alias

对 title 做：

- Unicode NFKC
- lowercase（Latin）
- 全半角统一
- 标点/多余空白标准化
- 保留数字、季数信息
- 日文长音/假名不做激进转换

与 `anime_title.normalized_title` 精确匹配。

若同名多作品，必须结合 year/format。

### Level 3 — Fuzzy Candidate

只用于产生 candidate，不默认自动绑定：

- trigram similarity
- token ratio
- year distance
- season token
- sequel markers (`2nd Season`, `Season 2`, `第2期`)

建议自动链接阈值 >= 0.93 且 top1-top2 margin >= 0.08；实际阈值通过 fixture 调整。

## 3. 新闻标题中的 entity extraction

MVP 不要求 LLM。使用：

1. known aliases dictionary
2. quoted title patterns（日文书名号、英文 title segment）
3. longest-match-first
4. sequel token parser

LLM/NLP 事件抽取放 P2。

## 4. News Dedup

### Stage A: same-source dedup

external ID / GUID / URL 唯一约束。

### Stage B: cross-source near duplicate

建立候选窗口：发布时间差 <= 48h 且至少一个 anime overlap；无 anime link 时可用 title similarity 召回。

评分示例：

- title normalized similarity: 0.45
- same anime: 0.25
- same named entities/cast terms: 0.10
- publication time proximity: 0.10
- URL/source-independent keyword overlap: 0.10

>= 0.90 自动聚合为同一 `story_cluster`；0.80–0.90 仅候选。

MVP 可以先实现 same-source + high-confidence cross-source，不要追求复杂事件聚类。

## 5. Canonical Display Record

当同一 story cluster 有多个报道：

- 不删除来源记录。
- API `news` 可返回 canonical entry + `sources[]`。
- 默认 canonical title 可以选择最高 trust + 最早发布来源；不得把多个标题拼成“新事实”。

## 6. Conflict Policy

对于日期、播出时间、staff 等结构化事实：

1. T0 Official
2. T1 official press/platform
3. DATABASE sources with explicit provenance
4. T2 media
5. T3 community
6. T4 unofficial aggregator

冲突时保留 evidence，并标记 `conflicted=true`；不要只保留赢家。

## 7. Manual Override

数据库预留：

- manual link/unlink
- merge anime
- split anime
- override canonical field

MVP 可通过 SQL/CLI 管理，不必提供 UI。
