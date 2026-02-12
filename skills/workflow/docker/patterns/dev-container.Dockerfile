# 开发环境容器化 Dockerfile
# 适用场景：为团队提供统一的开发环境

FROM ubuntu:22.04

# 避免交互式配置提示
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 安装基础工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 基础工具
    curl \
    wget \
    git \
    vim \
    # 构建工具
    build-essential \
    cmake \
    # 调试工具
    gdb \
    # Python（许多脚本需要）
    python3 \
    python3-pip \
    # 其他实用工具
    sudo \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 创建开发用户（与主机用户 ID 匹配，避免权限问题）
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# 切换到开发用户
USER $USERNAME
WORKDIR /home/$USERNAME

# 设置 git（可选）
RUN git config --global init.defaultBranch main

# 默认保持运行
CMD ["sleep", "infinity"]

# 使用说明：
# docker build -f dev-container.Dockerfile -t dev-env .
# docker run -it --rm \
#   -v $(pwd):/home/developer/workspace \
#   -w /home/developer/workspace \
#   dev-env bash
