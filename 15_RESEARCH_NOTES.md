# 15 — Research Notes & Verification Ledger

Research date: 2026-10-04.

This file records what was actually verified during pre-development research. It is not a substitute for release-time Source Probe.

## Verified structured interfaces

### AniList

- Official docs identify AniList as a public GraphQL API.
- Endpoint: `POST https://graphql.anilist.co`.
- Public reads do not require auth.
- Docs state normal rate limit 90 requests/minute, with a current degraded-state warning of 30 requests/minute at research time.
- Official Terms prohibit API-as-backup/storage, hoarding/mass collection, and certain competing/non-complementary services; commercial usage above the stated revenue threshold requires licensing discussion.

References:
- https://docs.anilist.co/guide/graphql/
- https://docs.anilist.co/guide/auth/
- https://docs.anilist.co/guide/rate-limiting
- https://docs.anilist.co/guide/terms-of-use

### Bangumi

- Official project documentation distinguishes legacy API from the newer `/v0/` public API and recommends the newer public API.
- Production base: `https://api.bgm.tv`.
- Official UA guidance asks non-browser clients to identify developer/application and warns default library UAs may be blocked.

References:
- https://bangumi.github.io/api/
- https://github.com/bangumi/api
- https://github.com/bangumi/api/blob/master/docs-raw/user%20agent.md

### Kitsu

- API docs describe base `https://kitsu.io/api/edge` and JSON:API semantics.

Reference:
- https://kitsu.docs.apiary.io/

### MyAnimeList

- Official API v2 documentation is published under MAL's developer configuration area.
- API base commonly documented as `https://api.myanimelist.net/v2`; application Client ID is required for public API usage patterns.
- Exact rate limits are not relied upon by this specification; implementation must handle 429 generically.

Reference:
- https://myanimelist.net/apiconfig/references/api/v2

### AnimeSchedule.net

- v3 is documented as active stable developer API.
- Application token required for documented non-OAuth endpoints.
- Rate-limit documentation currently states a global 120 requests/minute and exposes rate-limit headers.
- Site About page states it offers both a developer API and RSS feed.

References:
- https://animeschedule.net/api/v3/documentation
- https://animeschedule.net/api/v3/documentation/ratelimits
- https://animeschedule.net/about-us
- https://animeschedule.net/api-terms-of-use

### AnimeThemes

- Provides API access to anime OP/ED/theme resources and related entities.

References:
- https://api-docs.animethemes.moe/
- https://github.com/AnimeThemes/animethemes-api-docs

### Jikan

- Documentation explicitly identifies Jikan as an unofficial MyAnimeList API that scrapes MAL.
- Docs state 3 req/s, 60 req/min and 24h cache at research time.

Reference:
- https://docs.api.jikan.moe/

## Verified/identified news feeds

### Crunchyroll News

Crunchyroll News About page explicitly exposes an RSS feed. Current feed URL observed in RSS readers:

`https://cr-news-api-service.prd.crunchyrollsvc.com/v1/en-US/rss`

References:
- https://www.crunchyroll.com/news/about
- https://cr-news-api-service.prd.crunchyrollsvc.com/v1/en-US/rss

### Anime News Network

Current news-only feed observed as:

`https://www.animenewsnetwork.com/news/rss.xml?ann-edition=us`

All-content feed also exists, but MVP should use news-only.

### Other media feeds

The following feed URLs are widely exposed by the sites/feed directories but MUST be live-probed before enable:

- MyAnimeList News: `https://myanimelist.net/rss/news.xml`
- Anime Corner: `https://animecorner.me/feed/`
- Anime Herald: `https://www.animeherald.com/feed/`
- Tokyo Otaku Mode: `https://otakumode.com/news/feed`

The specification intentionally treats these as probe-gated rather than permanently guaranteed.

## Official channel structured ingestion

Google's official YouTube developer documentation describes Atom topic feeds using:

`https://www.youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID`

It also documents WebSub/PubSubHubbub push notifications for uploads/updates. MVP polls Atom; P1.1 can move to push.

Reference:
- https://developers.google.com/youtube/v3/guides/push_notifications

## Not verified as stable public API/RSS in this research

The following are high-value sources but are deliberately classified as Phase 2 Crawler until a documented/contracted structured interface is found:

- PR TIMES anime keyword/category pages
- Comic Natalie
- MANTANWEB Anime
- Anime!Anime!
- ORICON Anime
- Animate Times
- Dengeki Online
- Aniplex official website news
- KADOKAWA anime website news
- TOHO animation website news
- Bandai Namco Filmworks website news
- Pony Canyon anime website news
- NBCUniversal Anime/Music website news
- avex pictures website news
- King Amusement Creative website news
- individual anime official websites

Do not infer “crawler-only forever”; simply do not claim a structured contract until verified.
