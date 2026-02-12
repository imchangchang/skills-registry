---
name: docker-basics
description: Docker 容器化基础实践。镜像构建、容器管理、多阶段构建和开发环境配置。
created: 2026-02-12
status: stable
---

# Docker 基础实践

> 容器化应用的基础操作指南

## 适用场景

- 开发环境一致性
- 应用容器化部署
- 多阶段构建优化

## 核心概念

### Dockerfile 最佳实践

```dockerfile
# 多阶段构建
FROM python:3.11-slim as builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

FROM python:3.11-slim

WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .

ENV PATH=/root/.local/bin:$PATH
CMD ["python", "app.py"]
```

### 常用命令速查

```bash
# 构建
docker build -t myapp:latest .

# 运行
docker run -d -p 8080:8080 --name myapp myapp:latest

# 查看日志
docker logs -f myapp

# 进入容器
docker exec -it myapp /bin/sh

# 清理
docker system prune -f
```

### docker-compose 开发配置

```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "8080:8080"
    volumes:
      - .:/app
    environment:
      - DEBUG=1
```

## 迭代记录

- 2026-02-12: 初始创建，沉淀 Docker 基础实践
