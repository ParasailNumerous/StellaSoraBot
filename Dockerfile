# syntax=docker/dockerfile:1.4
FROM debian:trixie-backports

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    build-essential \
    pkg-config \
    ffmpeg \
    openjdk-26-jre-headless \
    nvidia-cuda-toolkit

# Install Microsoft repository and .NET 8 SDK
RUN curl -sSL https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb -o /tmp/packages-microsoft-prod.deb \
    && dpkg -i /tmp/packages-microsoft-prod.deb \
    && rm /tmp/packages-microsoft-prod.deb \
    && apt-get update && apt-get install -y --no-install-recommends dotnet-sdk-8.0

WORKDIR /root
ENV HOME=/root \
    PATH=/root/.local/bin:$PATH \
    CUDA_HOME=/usr/local/cuda

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install vgmstream-cli nightly
RUN curl -sSL https://github.com/vgmstream/vgmstream-releases/releases/download/nightly/vgmstream-linux-cli.tar.gz -o /tmp/vgmstream.tar.gz \
    && tar -xzf /tmp/vgmstream.tar.gz -C /tmp \
    && mv /tmp/vgmstream-cli /home/bot/.local/bin/vgmstream-cli \
    && rm /tmp/vgmstream.tar.gz

WORKDIR /app

COPY . .
RUN uv python install 3.13 \
    && uv python pin 3.13 \
    && uv sync --frozen --extra grounding

# Install Playwright dependencies
RUN uv run playwright install chromium --with-deps

