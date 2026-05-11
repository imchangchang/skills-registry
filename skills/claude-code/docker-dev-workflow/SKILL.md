---
name: docker-dev-workflow
description: "用于快速搭建 Docker + Dev Container 开发环境，确保宿主机与容器权限对齐，支持 CLI 和 VS Code 两种开发方式。"
agent: claude-code
---

# Docker 开发环境 Skill

## 目标

本 Skill 提供一套通用的 Docker 开发环境模板，帮助在任意工程中快速落地 Docker + Dev Container 开发能力。

核心特性：

- **CLI 模式**：通过 `build.sh` 脚本执行，支持本地和 CI 环境
- **Dev Container 模式**：通过 VS Code Remote - Containers 使用
- **权限对齐**：容器内文件属主与宿主机一致，无需 setuid 工具

## 模板文件

必须使用以下模板：

- `template/Dockerfile.build` - Docker 镜像构建文件
- `template/build.sh` - CLI 构建脚本
- `template/devcontainer.json` - Dev Container 配置

## 快速落地

### 第一步：复制模板到目标工程

在目标工程根目录创建 `docker/` 子目录，复制模板：

```bash
mkdir -p docker
cp <skill-path>/template/* docker/
```

### 第二步：替换占位符

编辑 `docker/build.sh`：

```bash
IMAGE_NAME="<your-project-name>-build:latest"  # 替换为你的项目名
BUILD_COMMAND="<your-build-command>"            # 替换为你的构建命令
```

编辑 `docker/devcontainer.json`：

```json
"name": "<your-project-name>"  // 替换为你的项目名
```

### 第三步：关联 Dev Container

```bash
mkdir -p .devcontainer
ln -sfn ../docker/devcontainer.json .devcontainer/devcontainer.json
```

### 第四步：调整 Dockerfile（如需要）

根据项目需求编辑 `docker/Dockerfile.build`：

- 修改基础镜像
- 增删构建依赖
- 调整工具链

## 权限机制

### CLI 模式

使用数字 UID/GID 映射：

```bash
docker run --rm -u $(id -u):$(id -g) -v $PWD:$PWD -w $PWD <image>
```

### Dev Container 模式

使用命名用户 + UID 自动对齐：

```json
"remoteUser": "builder",
"updateRemoteUserUID": true
```

两种方式结果一致：容器内生成的文件属主与宿主机用户相同。

## 使用方式

### CLI 构建

```bash
cd docker
./build.sh
```

或直接执行（假设 docker/ 在当前目录）：

```bash
./docker/build.sh
```

### VS Code Dev Container

1. 安装 VS Code [Remote - Containers 扩展](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. 打开项目目录
3. 按 `F1` → 选择 `Remote-Containers: Reopen in Container`

## 验证

### 验证容器用户 UID

```bash
docker run --rm -u $(id -u):$(id -g) -v $PWD:$PWD -w $PWD <image> id
```

预期：输出的 uid/gid 与宿主机的 `id` 命令一致。

### 验证工具链

```bash
docker run --rm -u $(id -u):$(id -g) -v $PWD:$PWD -w $PWD <image> which gcc make python3
```

### 验证 Dev Container 用户

```bash
docker run --rm <image> getent passwd builder
```

预期：返回 `builder` 用户的 passwd 记录。

## 常见问题

### 报错：unable to find user builder

原因：`remoteUser` 与容器内实际用户名不一致。

处理：

1. 确认 Dockerfile 中创建的用户名
2. 修改 `devcontainer.json` 中的 `remoteUser` 为一致的用户名
3. 删除旧容器后重建

### CLI 的 `whoami` 显示数字 UID

正常现象。数字 UID 不影响权限和构建功能。

### CI 环境构建失败

检查 `build.sh` 是否正确检测到 CI 环境。常见 CI 环境变量：`CI`、`GITLAB_CI`、`GITHUB_ACTIONS` 等。

## 设计原则

- **CLI 与 Dev Container 分离**：两条路径使用不同的权限机制
- **零依赖**：不依赖 setuid 或其他特权工具
- **可迁移**：模板为框架，可根据项目需求调整
- **权限安全**：容器内文件属主与宿主机一致
