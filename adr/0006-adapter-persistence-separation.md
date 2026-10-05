# ADR-0006 — Source Adapter 不直接持久化数据

- Status: Accepted
- Date: 2026-10-05

## Context

如果每个 Adapter 直接操作数据库，幂等、事务、重试、source health、provenance、cursor 和错误分类会散落到每个来源实现中，后续很难保证一致。

## Decision

Adapter 只负责：

1. `probe`
2. `fetch`
3. `validate`
4. `normalize`

统一 Ingestion Service 负责：

- transaction
- idempotency
- source cursor
- ETag/Last-Modified
- provenance
- retry/backoff
- source health
- dedup
- entity linking dispatch

## Consequences

- Adapter contract 可用 fixture 单独测试。
- 新增来源时不需要重复实现基础设施逻辑。
- 需要定义稳定的 normalized DTO contract。
