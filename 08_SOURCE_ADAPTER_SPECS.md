# 08 — Source Adapter Specifications

## 1. News RSS Adapters

所有 News RSS 共享 Generic RSS Adapter；source-specific code 只用于字段修正，不应复制 parser。

### 1.1 Crunchyroll News

- source_id: `news_crunchyroll_en`
- method: RSS
- feed: `https://cr-news-api-service.prd.crunchyrollsvc.com/v1/en-US/rss`
- trust: T1
- poll: 5 min
- required fields: title, link, published date
- optional: description/content/category
- notes: feed endpoint由 Crunchyroll News About/第三方 reader 实测可见；上线前 probe content-type/XML schema。

### 1.2 Anime News Network

- source_id: `news_ann_us`
- method: RSS
- feed: `https://www.animenewsnetwork.com/news/rss.xml?ann-edition=us`
- trust: T2
- poll: 5 min
- use news-only feed, not all feed
- unique preference: GUID → link

### 1.3 MyAnimeList News

- source_id: `news_mal`
- method: RSS
- feed: `https://myanimelist.net/rss/news.xml`
- trust: T2/T3
- poll: 10 min
- source probe required

### 1.4 Anime Corner

- source_id: `news_animecorner`
- method: RSS
- feed: `https://animecorner.me/feed/`
- trust: T2
- poll: 10 min
- WordPress content may include full HTML; excerpt length MUST cap at 1000 chars after sanitize

### 1.5 Anime Herald

- source_id: `news_animeherald`
- method: RSS
- feed: `https://www.animeherald.com/feed/`
- trust: T2
- poll: 15 min
- source probe required

### 1.6 Tokyo Otaku Mode

- source_id: `news_tokyo_otaku_mode`
- method: RSS
- feed: `https://otakumode.com/news/feed`
- trust: T2
- poll: 15 min
- filtering: keep anime/manga/news categories; merchandise-only content may remain but tag it rather than silently discard until product policy is set

---

## 2. Database API Adapters

### 2.1 Bangumi

- source_id: `db_bangumi`
- base: `https://api.bgm.tv`
- API: official Public API v0
- User-Agent: MUST be explicit and identify app/developer/project URL when available
- use cases: subject search, subject detail, relations, calendar as needed
- do not use private `/p1` API for MVP
- cache: reasonable; respect server behavior

Required normalized fields:

- bangumi subject ID
- `name`, `name_cn`
- aliases from infobox when safely parsed
- date/platform/type
- images as external URLs

### 2.2 MyAnimeList API v2

- source_id: `db_mal`
- base: `https://api.myanimelist.net/v2`
- auth: `X-MAL-CLIENT-ID` for public data / documented auth path
- scope: search by title/ID, details, seasonal/ranking if needed
- no full database sweep
- adapter disabled when client id absent

### 2.3 AnimeSchedule v3

- source_id: `db_animeschedule`
- base: `https://animeschedule.net/api/v3`
- auth: application Bearer token for documented private endpoints
- rate: docs currently describe 120 requests/min global; MUST read response headers, not hardcode assumption as invariant
- use: anime detail, timetable, cross IDs, official website field
- polling: timetable every 15 min; metadata by active-season scope

### 2.4 Kitsu

- source_id: `db_kitsu`
- base: `https://kitsu.io/api/edge`
- media type: `application/vnd.api+json`
- use: title aliases, dates, subtype/status, Kitsu ID
- parser MUST tolerate nullable/missing fields

### 2.5 AniList

- source_id: `db_anilist`
- endpoint: `POST https://graphql.anilist.co`
- public reads do not require auth
- current docs indicate normal limit 90 rpm but currently degraded state can be 30 rpm; implementation MUST read rate headers
- legal gate: default `legal_status=review`
- forbidden pattern: bulk hoarding/mirroring
- allowed implementation pattern: on-demand lookup by known ID/title and short-lived cache

### 2.6 AnimeThemes (P1.1)

- source_id: `db_animethemes`
- base: `https://api.animethemes.moe`
- use: opening/ending themes and linked external resources
- not used to create anime identity unless cross-id confirms it

### 2.7 Jikan (disabled fallback)

- source_id: `db_jikan`
- base: `https://api.jikan.moe/v4`
- docs: 3 req/s, 60 req/min; 24h cache
- status: disabled by default
- reason: unofficial MAL API, itself scrapes MAL; structured access does not remove upstream legal/reliability risk

---

## 3. Official YouTube Atom Adapter

- source kind: OFFICIAL
- access: RSS/Atom
- endpoint template: `https://www.youtube.com/feeds/videos.xml?channel_id={channel_id}`
- spec source: Google Developers Push Notifications docs
- poll: 5 min initially; P1.1 MAY use WebSub push

Fields:

- external_id = `yt:videoId`
- channel_id = `yt:channelId`
- title
- url from alternate link
- published
- updated
- author.name

Source Registry MUST contain:

- channel_id
- canonical channel URL
- owner organization
- verification evidence URL
- verified_at
- enabled

Do not infer official status based on channel name alone.

## 4. Source Adapter Contract Tests

每个 adapter fixture 至少覆盖：

- normal payload
- missing optional field
- malformed item among valid items
- duplicate item
- upstream 304（RSS/API where applicable）
- 429
- 500
- schema drift
- timeout

Parser failure for one item SHOULD NOT necessarily discard an entire feed；但顶层 schema 无法解析时整次 run 失败。
