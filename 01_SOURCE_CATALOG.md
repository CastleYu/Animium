# 01 — Source Catalog

研究日期：2026-10-04。站点能力会变化，开发阶段仍必须执行 Source Probe。

状态字段：

- `P1`: 首版实现
- `P1.1`: 首版后的小迭代
- `P2`: 爬虫阶段/后续
- `OPTIONAL`: 可选 fallback
- `HOLD`: 条款或稳定性不足，默认关闭

---

## A. 资讯源（NEWS）

| source_id | 站点 | 语言 | 接入方式 | 当前接口/Feed | 信任 | 阶段 | 备注 |
|---|---|---|---|---|---|---|---|
| `news_crunchyroll_en` | Crunchyroll News | EN | RSS | `https://cr-news-api-service.prd.crunchyrollsvc.com/v1/en-US/rss` | T1 | P1 | Crunchyroll About 页面明确提供 RSS；先实现 en-US |
| `news_ann_us` | Anime News Network | EN | RSS | `https://www.animenewsnetwork.com/news/rss.xml?ann-edition=us` | T2 | P1 | 可另加 `all/rss.xml`，MVP 使用 news-only |
| `news_mal` | MyAnimeList News | EN | RSS | `https://myanimelist.net/rss/news.xml` | T2/T3 | P1 | 上线前 probe；MAL 同时属于 DATABASE |
| `news_animecorner` | Anime Corner | EN | RSS | `https://animecorner.me/feed/` | T2 | P1 | WordPress feed；上线前 probe |
| `news_animeherald` | Anime Herald | EN | RSS | `https://www.animeherald.com/feed/` | T2 | P1 | 上线前 probe |
| `news_tokyo_otaku_mode` | Tokyo Otaku Mode News | EN | RSS | `https://otakumode.com/news/feed` | T2 | P1 | 内容范围包含商品/文化，需分类过滤 |
| `news_anitrendz` | Anime Trending | EN | RSS | site feed candidate | T2 | P1.1 | 先 probe 后决定是否启用 |
| `news_prtimes_anime` | PR TIMES 动漫相关 | JA | CRAWLER | keyword/category pages | T1 | P2 | 新闻稿价值高，但没有在本轮确认可依赖的公开 RSS/API |
| `news_comic_natalie` | コミックナタリー | JA | CRAWLER | website | T2 | P2 | 日本动画/漫画高价值媒体 |
| `news_mantan_anime` | MANTANWEB アニメ | JA | CRAWLER | website | T2 | P2 | 高频动漫资讯 |
| `news_animeanime` | アニメ！アニメ！ | JA | CRAWLER | website | T2 | P2 | 动漫产业/作品资讯 |
| `news_oricon_anime` | ORICON Anime | JA | CRAWLER | website | T2 | P2 | 娱乐/声优/动画 |
| `news_animate_times` | Animate Times | JA | CRAWLER | website | T2 | P2 | 声优/动画/活动 |
| `news_dengeki` | 电击 Online | JA | CRAWLER | website | T2 | P2 | ACG 综合源 |

### 资讯源 P1 说明

RSS feed 中即使存在 `content:encoded` 全文，MVP 也默认不对外输出全文。标准化字段最多包含：

- title
- canonical_url
- source
- published_at / updated_at
- author（若提供）
- feed excerpt/summary（长度受限）
- categories/tags（若提供）
- media thumbnail URL（仅作为外链元数据，默认不做代理）

---

## B. 数据库源（DATABASE）

| source_id | 站点 | 接入方式 | 接口 | 阶段 | 用途 | 关键约束 |
|---|---|---|---|---|---|---|
| `db_bangumi` | Bangumi | API | `https://api.bgm.tv/v0/...` | P1 | 中文名、别名、条目、人物/角色、关系 | 使用官方新 Public API；设置规范 User-Agent |
| `db_mal` | MyAnimeList | API | `https://api.myanimelist.net/v2` | P1 | MAL ID、title、season、ranking 等 | 需要 Client ID/应用；不得依赖 Jikan 替代官方主链路 |
| `db_animeschedule` | AnimeSchedule.net | API + RSS | `https://animeschedule.net/api/v3` / `/rss` | P1 | timetable、premiere、跨库 ID | 需要 application token；文档标明全局 120 req/min（可能变化） |
| `db_kitsu` | Kitsu | API | `https://kitsu.io/api/edge` | P1 | alternate metadata、Kitsu ID | JSON:API；必须容忍字段缺失 |
| `db_anilist` | AniList | GraphQL API | `https://graphql.anilist.co` | P1 (restricted) | enrichment、cross-id、title/season | 不得批量囤积；商业/竞争性用途存在明确条款限制 |
| `db_animethemes` | AnimeThemes | API | `https://api.animethemes.moe/...` | P1.1 | OP/ED、歌曲、主题曲关联 | enrichment，不是 canonical title 主源 |
| `db_jikan` | Jikan | REST API | `https://api.jikan.moe/v4` | OPTIONAL | MAL 数据 fallback/补充 | 非官方；底层抓 MAL；3 req/s、60 req/min 文档限制 |
| `db_anidb` | AniDB | API | HTTP/XML API | P2 | 旧作品、AniDB ID | 使用政策严格、接口老；不放入 MVP |
| `db_animeplanet` | Anime-Planet | CRAWLER | website | P2/HOLD | 标签/推荐候选 | 无官方稳定 API，不在 P1 |
| `db_anisearch` | aniSearch | CRAWLER | website | P2/HOLD | 欧洲向 metadata | 不在 P1 |

### 数据库源设计决策

不设“绝对唯一主数据库”。内部 `anime.id` 是本服务生成的稳定 ID。各数据库通过 `anime_external_id` 映射到内部实体，并按字段保存 provenance。

AniList 特别说明：官方 Terms 明确禁止把 API 当备份/存储服务、禁止 hoarding/mass collection，并限制竞争性服务；商业应用在一定收入以上需要许可。因此该 Adapter 必须：

- 默认按需查，不跑全库同步。
- 使用短 TTL cache。
- 可由环境变量一键禁用。
- 生产上线前人工确认使用场景是否符合条款。

---

## C. 动画官方源（OFFICIAL）

### C1. P1：结构化官方发布渠道

第一阶段不直接爬制作公司官网，而采用 YouTube 官方频道 Atom Feed。Google 官方文档明确列出了：

`https://www.youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID`

建议 allowlist 起步对象：

| official_group | 官方渠道类型 | P1 方法 | 阶段 |
|---|---|---|---|
| Aniplex | 官方 YouTube 频道 | YouTube Atom | P1 |
| KADOKAWA Anime | 官方 YouTube 频道 | YouTube Atom | P1 |
| TOHO animation | 官方 YouTube 频道 | YouTube Atom | P1 |
| Bandai Namco Filmworks / EMOTION | 官方 YouTube 频道 | YouTube Atom | P1 |
| Pony Canyon | 官方 YouTube 频道 | YouTube Atom | P1 |
| NBCUniversal Anime/Music | 官方 YouTube 频道 | YouTube Atom | P1 |
| avex pictures | 官方 YouTube 频道 | YouTube Atom | P1.1 |
| King Amusement Creative | 官方 YouTube 频道 | YouTube Atom | P1.1 |

`channel_id` 必须人工核验并在 Source Registry 中配置，不允许开发 Agent 根据频道名猜测。

P1 Official 数据仅包含：视频 ID、title、published/updated、channel ID/name、watch URL、source relation。若后续需要 description、duration、thumbnail 等，使用 YouTube Data API 作为 P1.1 enrichment，而不是抓 watch page。

### C2. P2：官网/制作方新闻页（Crawler）

| 站点 | 类型 | 阶段 | 说明 |
|---|---|---|---|
| Aniplex 官方站 | 制作/发行 | P2 | HTML Adapter |
| KADOKAWA Anime | 制作/出版 | P2 | HTML Adapter |
| TOHO animation | 发行/制作 | P2 | HTML Adapter |
| Bandai Namco Filmworks | 制作/发行 | P2 | HTML Adapter |
| Pony Canyon | 发行 | P2 | HTML Adapter |
| NBCUniversal Entertainment Japan Anime | 发行 | P2 | HTML Adapter |
| avex pictures | 制作/发行 | P2 | HTML Adapter |
| King Amusement Creative | 音乐/动画 | P2 | HTML Adapter |
| TMS Entertainment | 制作 | P2 | HTML Adapter |
| Shochiku Anime | 发行 | P2 | HTML Adapter |
| 各动画作品独立官网 | 作品官方 | P2 | 优先级最高但结构极不统一 |

---

## D. 第一阶段启用矩阵

| 能力 | 来源 | 默认启用 |
|---|---|---|
| News RSS | Crunchyroll | 是 |
| News RSS | ANN | 是 |
| News RSS | MAL | probe 后 |
| News RSS | Anime Corner | probe 后 |
| News RSS | Anime Herald | probe 后 |
| News RSS | Tokyo Otaku Mode | probe 后 |
| Metadata API | Bangumi | 是 |
| Metadata API | MAL | 凭证存在时 |
| Schedule API | AnimeSchedule | 凭证存在时 |
| Metadata API | Kitsu | 是 |
| Metadata API | AniList | 条款 gate 通过后 |
| Theme API | AnimeThemes | P1.1 |
| Official Atom | YouTube allowlist | channel ID 核验后 |
| Jikan | fallback | 否 |
| 所有 HTML Crawler | 全部 | 否 |

---

## E. 研究依据

- AniList GraphQL endpoint / public API: https://docs.anilist.co/guide/graphql/
- AniList rate limit: https://docs.anilist.co/guide/rate-limiting
- AniList Terms: https://docs.anilist.co/guide/terms-of-use
- Bangumi API v0: https://bangumi.github.io/api/
- Bangumi UA guidance: https://github.com/bangumi/api/blob/master/docs-raw/user%20agent.md
- Kitsu API: https://kitsu.docs.apiary.io/
- Jikan API: https://docs.api.jikan.moe/
- AnimeSchedule API: https://animeschedule.net/api/v3/documentation
- AnimeSchedule rate limits: https://animeschedule.net/api/v3/documentation/ratelimits
- AnimeSchedule RSS existence: https://animeschedule.net/about-us
- AnimeThemes API: https://api-docs.animethemes.moe/
- Crunchyroll RSS: https://www.crunchyroll.com/news/about
- ANN RSS endpoint evidence: https://www.animenewsnetwork.com/news/rss.xml?ann-edition=us
- YouTube Atom/push: https://developers.google.com/youtube/v3/guides/push_notifications

RSS availability for community/media feeds can change without versioning；因此 P1 必须实现自动 Source Probe，而不是把研究结果当永久事实。
