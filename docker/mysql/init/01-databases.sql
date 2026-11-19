-- MySQL 首次初始化时执行；业务表由各服务的 Flyway 管理。
CREATE DATABASE IF NOT EXISTS rbac_auth CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE DATABASE IF NOT EXISTS rbac_customer CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
