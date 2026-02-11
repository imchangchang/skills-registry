# Docker 速查表

## 常用命令

### 镜像管理
```bash
# 构建镜像
docker build -t myapp:latest .

# 使用特定 Dockerfile
docker build -f docker/Dockerfile -t myapp:latest .

# 查看镜像列表
docker images

# 删除镜像
docker rmi myapp:latest

# 清理未使用镜像
docker image prune
```

### 容器管理
```bash
# 运行容器
docker run -d --name myapp -p 8080:80 myapp:latest

# 运行并进入交互模式
docker run -it --rm myapp:latest bash

# 查看运行中的容器
docker ps

# 查看所有容器
docker ps -a

# 停止容器
docker stop myapp

# 删除容器
docker rm myapp

# 进入运行中的容器
docker exec -it myapp bash

# 查看日志
docker logs -f myapp
```

### Docker Compose
```bash
# 启动服务
docker compose up -d

# 构建并启动
docker compose up --build -d

# 停止服务
docker compose down

# 查看日志
docker compose logs -f

# 重启服务
docker compose restart

# 运行一次性命令
docker compose run --rm service-name command
```

## Dockerfile 指令速查

| 指令 | 用途 | 示例 |
|------|------|------|
| FROM | 基础镜像 | `FROM node:18-alpine` |
| RUN | 执行命令 | `RUN apt-get update` |
| COPY | 复制文件 | `COPY . /app` |
| ADD | 复制+解压 | `ADD archive.tar.gz /app` |
| WORKDIR | 设置工作目录 | `WORKDIR /app` |
| ENV | 环境变量 | `ENV NODE_ENV=production` |
| ARG | 构建参数 | `ARG VERSION=1.0` |
| EXPOSE | 暴露端口 | `EXPOSE 8080` |
| USER | 切换用户 | `USER nobody` |
| CMD | 默认命令 | `CMD ["node", "app.js"]` |
| ENTRYPOINT | 入口点 | `ENTRYPOINT ["docker-entrypoint.sh"]` |

## 安全最佳实践

```dockerfile
# ✅ 使用非 root 用户
RUN useradd -m appuser
USER appuser

# ✅ 使用特定版本标签
FROM node:18.19.0-alpine3.18
# 而不是 FROM node:latest

# ✅ 最小化层数
RUN apt-get update && apt-get install -y \
    package1 \
    package2 \
    && rm -rf /var/lib/apt/lists/*

# ✅ 不暴露敏感信息
# 不要在 Dockerfile 中写密码
# 使用运行时环境变量
```

## 调试技巧

```bash
# 进入正在运行的容器
docker exec -it container-name /bin/sh

# 查看容器详情
docker inspect container-name

# 查看容器资源使用
docker stats

# 复制文件到容器
docker cp local-file container-name:/path/

# 从容器复制文件
docker cp container-name:/path/file ./

# 查看构建历史
docker history myapp:latest

# 使用 BuildKit 构建（更快）
DOCKER_BUILDKIT=1 docker build -t myapp:latest .
```

## 嵌入式开发专用

```bash
# USB 设备映射（用于烧录）
docker run --privileged \
  -v /dev/bus/usb:/dev/bus/usb \
  stlink-tools st-info --probe

# 串口映射
docker run --device=/dev/ttyUSB0 \
  minicom-container

# 绑定挂载源码（开发时）
docker run -v $(pwd):/workspace \
  -w /workspace \
  arm-builder make
```
