# 00 — Scope & SDD Constitution

## 1. SDD 定义

本项目采用 Spec-Driven Development。实现顺序固定为：

1. Source Research
2. Scope Freeze
3. Requirements
4. Architecture & ADR
5. Data Contract / API Contract
6. Adapter Specifications
7. Test & Acceptance Contract
8. Task Decomposition
9. Implementation
10. Verification
11. Release

代码不是规格的替代品。遇到规格冲突时，优先级为：

`法律/来源条款 > 本文件原则 > ADR > Requirements > API/Data contracts > Implementation Plan > 代码现状`

## 2. 产品目标

对上游多个动漫资讯与元数据库进行标准化，向客户端提供统一、可分页、可过滤、可溯源的 API。

MVP 的核心输出：

- 标准化资讯条目
- 动画实体及外部 ID 映射
- 放送时间/季度信息
- 官方频道发布条目
- 来源健康度
- 动画与资讯关联关系

## 3. 非目标

MVP 明确不做：

- HTML 爬虫
- 第三方新闻全文镜像
- 图片代理/CDN 镜像
- 用户追番/社交功能
- 评论聚合
- 自动翻译全文
- 大模型事件抽取
- 推荐系统
- 评分合并为单一“绝对评分”
- 自建搜索引擎集群（PostgreSQL FTS/trigram 足够）

## 4. Source 分类

### 4.1 NEWS
媒体、新闻编辑部、新闻聚合页面。输出 `news_article`。

### 4.2 DATABASE
动漫条目数据库、播出日历、OP/ED 资料库。输出 `anime`、`external_identifier`、`schedule_entry` 等。

### 4.3 OFFICIAL
制作/发行/版权方、作品委员会、官方频道、官方作品网站。输出 `official_post`，并可作为事实冲突时的高权重证据。

一个域名可以承担多个角色，但在 Source Registry 中必须拆成不同 `source_id` 或 endpoint role。

## 5. Access Method 分类

- `API`: REST / GraphQL / JSON:API 等结构化接口。
- `RSS`: RSS 2.0、Atom、站点 feed。
- `CRAWLER`: HTML 页面解析、浏览器自动化、未公开 web endpoint 逆向。

MVP 只允许 `API` 和 `RSS`。任何 Adapter 不得在失败时静默 fallback 到 CRAWLER。

## 6. 信任等级

- `T0`: 作品/制作委员会/版权方官方发布。
- `T1`: 官方发行商、平台 newsroom、正式新闻稿。
- `T2`: 专业媒体。
- `T3`: 社区数据库/社区编辑数据。
- `T4`: 非官方代理 API、二次聚合。

信任等级只用于冲突排序，不能代替事实验证。

## 7. 数据所有权原则

内部系统拥有：

- 内部 UUID/ULID
- 标准化字段
- 自己计算的 hash
- 自己计算的匹配/去重分数
- 数据血缘/健康状态

第三方内容始终保留 source attribution。不得通过字段重组把第三方完整数据集变成“内部自有数据”。

## 8. Source Enable Gate

每个来源上线必须同时满足：

- Endpoint 当前可访问
- 格式通过 parser contract test
- 有明确请求头与身份策略
- 限流策略已实现
- 法务/条款状态不为 `blocked`
- Source Registry 中 `enabled=true`
- 健康检查通过

## 9. 变更控制

以下变化必须新增 ADR：

- 更换核心框架/数据库/队列
- 改内部 anime identity 策略
- 允许爬虫进入 MVP
- 开启全文存储或全文再分发
- 引入 LLM 作为必经链路
- 修改 API 破坏性字段
- 修改 source trust tier 规则
