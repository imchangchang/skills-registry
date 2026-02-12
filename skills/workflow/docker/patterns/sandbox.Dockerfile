# 沙箱环境 Dockerfile
# 适用场景：运行不受信任的代码或工具
# 特点：最小权限、最小镜像、网络隔离

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# 安装最小必要工具
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        # 根据需要添加
        # python3 \
        # jq \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 创建受限用户
RUN useradd --create-home --shell /bin/bash sandbox \
    && mkdir -p /home/sandbox/work \
    && chown -R sandbox:sandbox /home/sandbox

# 切换到受限用户
USER sandbox
WORKDIR /home/sandbox

# 限制网络（可选，需要在运行时配置）
# 使用：docker run --network none ...

# 保持运行，等待任务
CMD ["sleep", "infinity"]

# 使用说明：
# docker build -f sandbox.Dockerfile -t sandbox .
# docker run -it --rm \
#   --network none \
#   --read-only \
#   --tmpfs /tmp:noexec,nosuid,size=100m \
#   -v $(pwd)/task:/home/sandbox/work:ro \
#   sandbox bash
