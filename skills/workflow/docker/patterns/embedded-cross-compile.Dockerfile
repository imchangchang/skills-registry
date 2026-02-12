# 嵌入式交叉编译 Dockerfile
# 适用场景：在 x86 机器上构建 ARM 嵌入式固件

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 安装基础工具和 ARM 交叉编译工具链
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 基础构建工具
    build-essential \
    cmake \
    make \
    git \
    # ARM 交叉编译工具链（以 ARM GCC 为例）
    gcc-arm-none-eabi \
    libnewlib-arm-none-eabi \
    libstdc++-arm-none-eabi-newlib \
    # 常用工具
    wget \
    curl \
    python3 \
    python3-pip \
    # 固件处理工具
    binutils-arm-none-eabi \
    # 清理
    && rm -rf /var/lib/apt/lists/*

# 安装 ST-Link 工具（用于烧录，可选）
RUN apt-get update && apt-get install -y --no-install-recommends \
    libusb-1.0-0-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# 可选：从源码安装最新版 stlink 工具
# RUN git clone https://github.com/stlink-org/stlink.git /tmp/stlink \
#     && cd /tmp/stlink \
#     && make release \
#     && make install \
#     && rm -rf /tmp/stlink

# 创建工作目录
WORKDIR /workspace

# 使用非 root 用户（避免生成的文件权限问题）
ARG USERNAME=builder
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && chown -R $USERNAME:$USERNAME /workspace

USER $USERNAME

# 验证工具链
RUN arm-none-eabi-gcc --version

# 默认命令
CMD ["/bin/bash"]

# 使用说明：
# docker build -f embedded-cross-compile.Dockerfile -t arm-builder .
#
# 构建项目：
# docker run --rm -it \
#   -v $(pwd):/workspace \
#   -w /workspace \
#   arm-builder \
#   make clean all
#
# 使用 USB 烧录（需要特权模式）：
# docker run --rm --privileged \
#   -v $(pwd):/workspace \
#   -v /dev/bus/usb:/dev/bus/usb \
#   arm-builder \
#   st-flash write firmware.bin 0x8000000
