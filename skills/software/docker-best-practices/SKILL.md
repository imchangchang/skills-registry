---
name: docker-best-practices
description: Docker 容器化最佳实践，包含安全加固、多服务编排、开发环境标准化。基于 OpenClaw 项目实践。
created: 2024-01-15
status: draft
---

# Docker 最佳实践

## 适用场景
- 开发环境标准化
- 多服务应用部署
- 需要隔离的运行环境
- CI/CD 流水线

## 核心原则

### 1. 安全优先

#### 使用非 root 用户运行（强制）
```dockerfile
# ❌ 错误：使用 root 运行
FROM node:22
CMD ["node", "app.js"]

# ✅ 正确：创建并切换到非 root 用户
FROM node:22-bookworm
RUN useradd --create-home --shell /bin/bash appuser
USER appuser
WORKDIR /home/appuser
CMD ["node", "app.js"]
```

#### 最小化基础镜像
```dockerfile
# 生产环境使用精简镜像
FROM debian:bookworm-slim  # ~30MB
# 而不是
FROM ubuntu:latest         # ~80MB
```

### 2. 构建优化

#### 利用层缓存
```dockerfile
# ✅ 先复制依赖清单，再安装
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# 后复制源代码（经常变动）
COPY . .
RUN pnpm build
```

#### 多阶段构建（嵌入式开发场景）
```dockerfile
# 构建阶段
FROM gcc:13 AS builder
WORKDIR /build
COPY . .
RUN make

# 运行阶段（最小化）
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    libusb-1.0-0 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /build/firmware-tool /usr/local/bin/
USER nobody
CMD ["firmware-tool"]
```

### 3. 服务编排

#### docker-compose 结构
```yaml
services:
  # 主服务
  app-gateway:
    image: myapp:latest
    environment:
      - APP_TOKEN=${APP_TOKEN}
    volumes:
      - ${CONFIG_DIR}:/app/config
    ports:
      - "8080:8080"
    restart: unless-stopped
    init: true  # 使用 init 进程处理僵尸进程

  # CLI 工具服务（一次性/交互式）
  app-cli:
    image: myapp:latest
    environment:
      - APP_TOKEN=${APP_TOKEN}
    volumes:
      - ${CONFIG_DIR}:/app/config
    stdin_open: true
    tty: true
    profiles: ["cli"]  # 默认不启动
```

#### 使用技巧
```bash
# 启动主服务
docker compose up -d app-gateway

# 运行 CLI（一次性）
docker compose run --rm app-cli command

# 查看日志
docker compose logs -f app-gateway
```

## 代码模式

### 模式 1：开发环境容器化

见 patterns/dev-container.Dockerfile

适用：为团队提供统一的开发环境

### 模式 2：多架构支持

见 patterns/multi-arch.Dockerfile

适用：嵌入式交叉编译（x86 构建，ARM 运行）

### 模式 3：沙箱环境

见 patterns/sandbox.Dockerfile

适用：运行不受信任的代码/工具

### 模式 4：Docker Compose 完整示例

见 patterns/docker-compose.yml

## .dockerignore 策略

### 必须排除的内容
```
# 版本控制
.git
.gitignore

# 依赖（会在容器内安装）
node_modules
vendor
__pycache__
*.pyc

# 构建产物
dist
build
*.o
*.a

# 临时文件
.tmp
*.log
coverage

# 开发环境
.vscode
.idea
*.swp

# 大型资源（如不需要）
assets/videos/
*.mp4
*.zip
```

### 嵌入式项目特殊注意
```
# 排除固件二进制（在容器内构建）
*.bin
*.hex
*.elf

# 排除 IDE 配置
.mxproject
.settings/
Debug/
Release/
```

## 环境变量配置

### 安全传递敏感信息
```bash
# ✅ 使用环境文件
docker run --env-file .env myapp

# ✅ 使用 compose 时，在 .env 中定义
# .env
APP_TOKEN=secret
CONFIG_DIR=/home/user/.myapp

# docker-compose.yml
services:
  app:
    environment:
      - APP_TOKEN=${APP_TOKEN}
```

### 开发 vs 生产配置
```yaml
# docker-compose.yml（基础配置）
services:
  app:
    image: myapp:${VERSION:-latest}
    environment:
      - NODE_ENV=${NODE_ENV:-production}

# docker-compose.override.yml（开发覆盖）
services:
  app:
    volumes:
      - ./src:/app/src  # 热重载
    environment:
      - NODE_ENV=development
      - DEBUG=1
```

## 常见问题

### 问题 1：容器内时区不正确
**现象**：日志时间不对
**解决**：
```dockerfile
RUN apt-get update && apt-get install -y tzdata
ENV TZ=Asia/Shanghai
```

### 问题 2：权限问题（卷挂载）
**现象**：容器内无法写入挂载的目录
**解决**：
```dockerfile
# 在 Dockerfile 中调整权限
RUN chown -R appuser:appuser /app/data
```

或运行时：
```bash
docker run --user $(id -u):$(id -g) -v $(pwd)/data:/app/data myapp
```

### 问题 3：构建上下文过大
**现象**：docker build 很慢
**解决**：
- 检查 .dockerignore
- 使用 BuildKit：`DOCKER_BUILDKIT=1 docker build`

## 工具脚本

### 自动设置脚本

见 patterns/docker-setup.sh

功能：
- 检查 Docker 环境
- 自动生成配置
- 一键启动服务

## 参考资料

- references/security-hardening.md - Docker 安全加固指南
- references/compose-patterns.md - Compose 高级模式
- references/build-optimization.md - 构建优化技巧

## 迭代记录

- 2024-01-15: 初始创建，基于 OpenClaw 项目实践
