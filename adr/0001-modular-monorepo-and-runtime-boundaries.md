# ADR-0001 — 采用模块化 Monorepo 与 API/Worker 运行边界

- Status: Accepted
- Date: 2026-10-05

## Context

项目需要同时承载公开 REST API、定时采集、异步任务、多个来源 Adapter、数据持久化和可观测性。当前阶段仍处于 MVP，过早拆分微服务会显著增加部署、追踪、契约与本地开发复杂度。

## Decision

采用单仓库模块化 Monorepo：

- `apps/api`: Public REST API
- `apps/worker`: ingestion worker + scheduler
- `packages/core`: domain、normalize、matching、dedup
- `packages/db`: schema、migration、repository
- `packages/adapters`: RSS/API/Atom adapters
- `packages/config`: env/source registry/config schema
- `packages/observability`: logs、metrics、health

部署时至少拆成两个独立进程：

1. API process
2. Worker process

PostgreSQL 为持久化真源，Redis/BullMQ 仅承担队列、短期缓存和运行时协调。

## Consequences

优点：

- 本地和 CI 简单。
- 共享类型与领域逻辑不需要跨服务发布。
- 将来仍可按边界拆服务。

代价：

- 必须严格控制模块依赖方向。
- Worker 与 API 不得通过共享内存耦合。
