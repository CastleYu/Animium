# ADR-0003 — MVP 只允许 API、RSS 与 Atom，不实现 HTML Crawler

- Status: Accepted
- Date: 2026-10-05

## Context

高价值动漫资讯源中，有一部分只有 HTML 页面。若首版同时支持浏览器/HTML 抓取，将引入 DOM 漂移、反爬、robots/ToS、浏览器运行环境、抓取并发和维护成本，削弱 MVP 对统一模型与幂等采集的验证。

## Decision

MVP 只执行：

- REST/GraphQL/JSON:API 等公开结构化 API
- RSS 2.0
- Atom

`access_method=CRAWLER` 的来源只允许登记，禁止调度和执行。

API/RSS 失败时禁止自动降级为 HTML 抓取。

## Consequences

- 第一阶段来源数量受限，但稳定性、合规性和测试边界更清晰。
- Phase 2 可在独立队列和独立 Adapter 类型中增加 Crawler。
