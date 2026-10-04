# 10 — Test & Acceptance

## 1. Test Pyramid

### Unit

- URL normalization
- title normalization
- RSS parsing
- per-source normalizer
- cursor encoding
- dedupe scoring
- entity candidate scoring

### Contract

每个 Adapter 用固定 fixture 验证输出 DTO schema。

### Integration

- PostgreSQL repositories
- Redis/BullMQ jobs
- ingestion transaction
- duplicate replay
- source health transitions

### Live Source Smoke

不在普通 CI 强制；release pipeline/manual job 执行：

- HEAD/GET reachability
- auth validity
- parse one payload
- schema fingerprint
- rate-limit headers

### E2E

API against seeded DB。

## 2. Required Test IDs

- `UT-RSS-001`: RSS 2.0 normal parse
- `UT-ATOM-001`: YouTube Atom parse
- `UT-URL-001`: canonical URL normalization
- `UT-TITLE-001`: Japanese/English title normalization
- `UT-DEDUPE-001`: same GUID idempotency
- `IT-INGEST-001`: same feed replay 10x no duplicate
- `IT-INGEST-002`: one source 500 does not fail another source
- `IT-RATE-001`: 429 honors Retry-After
- `IT-SCHEMA-001`: schema drift marks degraded
- `IT-ENTITY-001`: exact external ID links correct anime
- `IT-ENTITY-002`: ambiguous exact title does not auto-link wrong item
- `E2E-NEWS-001`: news filter/source/language/time
- `E2E-ANIME-001`: anime external id lookup
- `E2E-SCHED-001`: schedule timezone presentation
- `E2E-SOURCE-001`: `/v1/sources` reports health
- `SEC-XML-001`: XXE payload not resolved
- `SEC-LOG-001`: bearer token not present in log capture

## 3. Acceptance Scenarios

### AC-01 RSS ingest

Given source enabled and feed contains 20 items  
When ingestion runs twice unchanged  
Then first run inserts <=20 normalized source items and second inserts 0 duplicates.

### AC-02 Source isolation

Given ANN returns 500 and Crunchyroll works  
When scheduled ingestion runs  
Then Crunchyroll data is committed and ANN run is failed/degraded independently.

### AC-03 Exact entity link

Given a source payload carries MAL ID 21 and mapping already exists  
When normalized  
Then relation confidence = 1.0 and no fuzzy title lookup can override it.

### AC-04 Ambiguous title

Given two anime share normalized title  
When year/format are insufficient  
Then system does not auto-link and records matching candidates.

### AC-05 Copyright boundary

Given RSS contains full HTML content  
When public `/v1/news/{id}` is called  
Then response does not expose unbounded/full third-party article body.

### AC-06 Restricted source

Given AniList `legal_status=review` and production policy requires approved  
When scheduler runs  
Then adapter is skipped with `LEGAL_DISABLED` status.

## 4. Release Gate

MVP release requires：

- 100% MUST requirements mapped to tests/acceptance.
- no failing unit/integration/E2E tests.
- at least 4 NEWS sources source-probe pass.
- at least 4 DATABASE sources configured or documented why disabled.
- at least 3 verified official channel feeds configured.
- migrations tested from empty DB.
- backup/restore smoke passed.
- OpenAPI validation passed.
- no known critical/high dependency vulnerability without documented exception.
