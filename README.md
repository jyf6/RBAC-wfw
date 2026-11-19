# RBAC-wfw
联系java微服务
# RBAC 微服务基础框架

本项目使用 JDK 25、Maven、Spring Boot、Spring Cloud Gateway、MyBatis-Plus、Sa-Token、Flyway 和 Vue 3。当前仅提供基础工程，不包含登录、客户管理或权限业务。

## 服务

| 模块 | 地址 | 作用 |
| --- | --- | --- |
| gateway | http://localhost:8080 | 路由 `/api/auth/**`、`/api/customers/**`，路径保持不变 |
| auth-service | http://localhost:8081 | 认证服务骨架 |
| customer-service | http://localhost:8082 | 客户服务骨架 |
| frontend | http://localhost:5173 | Vue 3；开发时 `/api` 代理到网关 |

## 运行

需要 JDK 25、Maven 3.6.3+ 和 Node.js 20.19+ 或 22.12+。Windows PowerShell 例如：

```powershell
$env:JAVA_HOME = 'C:\Users\Lenovo\jdks\temurin-25.0.4'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
java -version
mvn -version
mvn clean package
```

分别在三个终端运行：

```powershell
java -jar gateway/target/gateway-0.0.1-SNAPSHOT.jar
java -jar auth-service/target/auth-service-0.0.1-SNAPSHOT.jar
java -jar customer-service/target/customer-service-0.0.1-SNAPSHOT.jar
```

前端：

```powershell
cd frontend
npm ci
npm run dev
```

健康检查：各服务的 `/actuator/health`。网关转发目标可通过 `AUTH_SERVICE_URL` 和 `CUSTOMER_SERVICE_URL` 覆盖。

## 数据库与迁移

默认使用各进程独立的 H2 内存数据库，重启后数据会消失，仅用于本地启动。每个业务服务独立维护 `src/main/resources/db/migration`，启动时自动运行 Flyway。当前 V1 仅验证迁移机制；新增数据库结构时增加新的版本化脚本，已应用的脚本不要修改。迁移须同时兼容所使用的数据库。

也可启用 `mysql` profile；先分别创建 `rbac_auth` 和 `rbac_customer` 数据库并准备各自的账号，然后在各服务自己的终端设置：

```powershell
$env:SPRING_PROFILES_ACTIVE = 'mysql'
$env:DB_URL = 'jdbc:mysql://localhost:3306/rbac_auth?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai'
$env:DB_USER = 'your_user'
$env:DB_PASSWORD = 'your_password'
java -jar auth-service/target/auth-service-0.0.1-SNAPSHOT.jar
```

客户服务同样设置独立数据库 URL 和凭据。请勿将实际密码提交到仓库。

## 安全边界

Sa-Token 已引入两个业务服务，并统一令牌头配置；当前没有登录接口、权限规则、网关鉴权或共享会话存储，也没有实现微服务间令牌共享。默认 Sa-Token 内存存储不能跨服务共享，不能用于生产认证。接入业务时需要先配置共享存储、登录认证和服务端权限校验，并限制内部服务访问。当前网关路由只是转发，不提供安全保护。

## 本地中间件（Docker Compose）

根目录的 `docker-compose.yml` 提供独立的 MySQL、Redis 和 Nacos，仅用于本地开发。当前项目不会自动使用这些服务：业务服务默认仍使用 H2，Sa-Token 和服务发现尚未接入 Redis、Nacos。

首次使用前复制配置并修改 MySQL 密码：

```powershell
Copy-Item .env.example .env
# 编辑 .env，设置 MYSQL_ROOT_PASSWORD，然后按需启动：
docker compose up -d
```

| 服务 | 本机地址 | 说明 |
| --- | --- | --- |
| MySQL | `127.0.0.1:13306` | 初次创建数据卷时创建 `rbac_auth`、`rbac_customer`；账密为 `root` 与 `.env` 中的密码 |
| Redis | `127.0.0.1:16379` | 本地开发未设置密码，使用 AOF 持久化 |
| Nacos | 控制台 `http://localhost:18880`；服务 `localhost:8848` | 单机模式，使用内置 Derby，客户端 gRPC 端口为 `9848` |

端口仅绑定本机，避免与已有服务冲突；可在 `.env` 中调整。Nacos 的客户端 gRPC 端口必须保持为服务端口加 1000，修改端口时需同时调整这两个值。Nacos 和 Redis 当前未启用认证，不适合生产或对外暴露。Nacos 使用独立数据卷持久化，未使用 MySQL 存储。

要让业务服务使用此 MySQL，在各自的终端启用 `mysql` profile，并将 `DB_URL` 的端口改为 `13306`、设置对应数据库名与凭据。Compose 创建数据库的脚本仅在 MySQL 数据卷首次初始化时运行；后续表结构变更由各服务的 Flyway 迁移脚本管理。普通 `docker compose down` 保留数据卷，请勿随意使用 `down -v`。

Nacos 3.3 启动需要 `NACOS_AUTH_TOKEN`、`NACOS_AUTH_IDENTITY_KEY` 和 `NACOS_AUTH_IDENTITY_VALUE`。项目 Compose 从 `.env` 读取这三个值；已有 `.env` 的情况下，请参考 `.env.example` 补充，并替换示例值。修改 Compose 环境变量后，需要重新创建 Nacos 容器才会生效。
