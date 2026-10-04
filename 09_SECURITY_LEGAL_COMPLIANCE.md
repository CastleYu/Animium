# 09 — Security, Legal & Compliance

## 1. 版权边界

MVP 不以“新闻全文再发布”为产品能力。

默认允许对外：

- 标题
- 来源名称
- 来源 URL
- 时间
- Feed 自带短摘要（限制长度，并保留 attribution）
- 自己计算的分类/关联/去重信息

默认不对外：

- 第三方完整正文
- 第三方高清原图二次托管
- 付费墙内容
- 绕过登录/反爬得到的内容

如果 feed 自身包含全文，也不等于自动获得再分发许可。

## 2. AniList 专项

截至调研日期，官方 API Terms 表示：

- 非商业可免费使用；商业收入超过指定阈值需要商业许可。
- 禁止把 API 用作备份/数据存储服务。
- 禁止 hoarding/mass collection。
- 限制竞争性、非互补的 anime/manga list/tracker 服务。

因此：

- production enable 前必须完成使用场景复核。
- 不做全量同步。
- 不做长期完整 snapshot。
- 不把 AniList 作为服务的唯一/主要复制数据库。

## 3. RSS/News ToS

每个 source 必须记录：

- terms_url
- robots_url（Crawler 阶段）
- redistribution_status
- commercial_status
- reviewed_at
- reviewer_note

P1 RSS 仍需遵守站点条款；RSS 可机器读取不等同于无条件商业再分发。

## 4. Credentials

Secrets：

- MAL_CLIENT_ID
- ANIMESCHEDULE_TOKEN
- optional API keys
- database credentials
- Redis credentials

要求：

- `.env` 不提交
- `.env.example` 只有变量名
- log redaction
- CI 使用 secret store
- 生产环境最低权限账户

## 5. SSRF

Source endpoints 只能来自静态/受控 registry。Public API 不允许用户传任意 URL 触发服务端 fetch。

## 6. XML Security

RSS parser MUST 禁用外部实体解析（XXE）。限制单次 payload size，例如 5–10 MB（source-specific）。

## 7. HTML Sanitization

Feed description 可能包含 HTML。存储前：

- strip script/style/iframe
- 转纯文本或严格 sanitize
- public response 默认纯文本 excerpt

## 8. URL Validation

- 只允许 http/https。
- canonical URL 正规化但保留 original URL。
- 不自动访问 feed item 中任意嵌入 URL。

## 9. Data Retention

- raw diagnostic sample <= 7d default
- ingest logs 30–90d
- canonical metadata retained while source attribution remains valid
- user data：MVP 无用户账户，因此不处理个人追番数据

## 10. Security Headers / API

- reverse proxy TLS
- request size limit
- rate limit
- CORS allowlist configurable
- no stack trace in production
- dependency audit in CI

## 11. Legal Gate Matrix

| 状态 | 行为 |
|---|---|
| approved | 可启用 |
| review | 开发/测试可选；生产默认 disabled |
| blocked | 不允许请求 |

如果条款不明确，不应由开发 Agent 自行判断“应该没问题”；标记 review 并继续其他来源。
