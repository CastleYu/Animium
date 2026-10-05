# ADR-0007 — 基础设施可迁移性与运行时连接边界

- Status: Accepted
- Date: 2026-10-06

## Context

Animium 本地开发使用 Docker Compose，但生产环境可能采用：

- 单机 Docker/Compose
- 独立 PostgreSQL/Redis 服务器
- 云托管 PostgreSQL
- 云托管 Redis
- 私网或 TLS 公网连接

如果应用层依赖 `localhost`、Docker service name、固定 IP，或由各业务模块自行创建数据库/Redis 客户端，部署拓扑变化会演变为代码变更，并增加连接池爆炸、migration 竞争和故障耦合风险。

## Decision

### 1. Infrastructure is configuration

PostgreSQL 与 Redis 被定义为外部网络基础设施依赖。

Docker Compose 仅是本地开发与可选单机部署方式，不是应用架构的一部分。

同一应用构建产物必须仅通过 env/Secret 切换不同基础设施 endpoint。

### 2. PostgreSQL boundary

所有数据库访问统一经过 Database Factory/Pool 与 Repository：

```text
Config → createDatabase(config) → Pool/Driver → Repository → Service
```

业务代码不得：

- 自行创建 Pool/Client
- 直接读取 `DATABASE_URL`
- 写死 hostname/IP
- 按 NODE_ENV 选择数据库主机

连接配置必须支持 pool size、connect/idle/statement timeout 和可选 TLS/CA。

### 3. Migration boundary

Migration 是显式 one-shot 部署步骤。

API 与 Worker 启动不得自动执行 migration，防止多 replica 竞争迁移。

### 4. Redis boundary

Queue 与 Cache 逻辑分离，并通过各自 factory 暴露能力。

业务代码不得：

- 自行创建 Redis client
- 使用 Redis 私有 key 作为领域合同
- 直接操作 BullMQ 内部 key

BullMQ namespace 使用 BullMQ 的 `prefix` 配置，不使用 ioredis `keyPrefix`。

### 5. Durability

PostgreSQL 是 canonical datastore。

Redis 是 operational datastore。Redis 故障/重建不能导致 canonical anime/news/source cursor 永久丢失，但 queue state 具有运行价值，因此生产 queue backend SHOULD 使用适当持久化和禁止淘汰队列 key 的内存策略。

### 6. Readiness

API：

- PostgreSQL/config 为硬依赖。
- 纯 cache Redis 故障可降级，不单独触发 API not-ready。

Worker：

- PostgreSQL/config/queue backend 为硬依赖。

### 7. Network and secrets

连接密码、TLS CA、客户端证书等通过 env/Secret/file mount 注入，不进入源码、镜像、Source Registry 或日志。

单机部署默认不向公网暴露 PostgreSQL/Redis 端口。

## Consequences

优点：

- 本地、VPS、独立数据库服务器和托管服务间迁移最小化。
- 业务代码不依赖基础设施拓扑。
- 避免连接池与 migration 生命周期散落。

代价：

- Milestone 0 必须先实现 config/factory 边界。
- Integration test 需要覆盖至少两种 endpoint topology。
- 运维必须明确 queue Redis 的耐久性，而不能把它视为完全可丢弃缓存。
