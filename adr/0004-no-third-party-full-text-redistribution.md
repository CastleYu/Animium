# ADR-0004 — 不提供第三方新闻全文镜像

- Status: Accepted
- Date: 2026-10-05

## Context

部分 RSS Feed 会携带完整 HTML 正文，但“可机器读取”不等于获得全文再分发授权。全文镜像也会扩大版权、存储和数据清理风险。

## Decision

Public API 默认只提供：

- title
- source
- source/canonical URL
- published/updated time
- 受限长度 excerpt
- category/tag
- anime relation
- provenance

不提供第三方完整正文，不代理保存第三方高清原图。

诊断性 raw payload 只能限量、限期保留，且不能直接暴露给 Public API。

## Consequences

- 降低版权和再分发风险。
- 客户端需要通过原始链接阅读完整文章。
- 如未来确需全文能力，必须新增法律评估和 ADR。
