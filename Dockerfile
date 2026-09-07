# syntax=docker/dockerfile:1.4
FROM debian:trixie-backports

ENV DEBIAN_FRONTEND=noninteractive

# Prerequisites for adding repos and downloading
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    wget

# System packages
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    pkg-config \
    ffmpeg \
    openjdk-25-jre-headless

# Install Microsoft repository and .NET 8 SDK
RUN wget https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb \
    && dpkg -i /tmp/packages-microsoft-prod.deb \
    && rm /tmp/packages-microsoft-prod.deb \
    && apt-get update && apt-get install -y dotnet-sdk-8.0

# CUDA toolkit
# from https://docs.nvidia.com/cuda/cuda-installation-guide-linux/#debian
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/debian13/x86_64/cuda-keyring_1.1-1_all.deb -O /tmp/cuda-keyring.deb \
    && dpkg -i /tmp/cuda-keyring.deb \
    && rm /tmp/cuda-keyring.deb \
    && apt-get update && apt-get install -y cuda-toolkit

# Install vgmstream-cli nightly
RUN curl -sSL https://github.com/vgmstream/vgmstream-releases/releases/download/nightly/vgmstream-linux-cli.tar.gz -o /tmp/vgmstream.tar.gz \
    && tar -xzf /tmp/vgmstream.tar.gz -C /tmp \
    && mv /tmp/vgmstream-cli /usr/local/bin/vgmstream-cli \
    && rm /tmp/vgmstream.tar.gz

RUN useradd -G wheel -s /bin/bash bot \
    && mkdir -p /app \
    && chown -R bot:bot /app

RUN rm -rf /var/lib/apt/lists/*

# Switch away from root
USER bot
WORKDIR /app

ENV HOME=/home/bot \
    PATH="/home/bot/.local/bin:/usr/local/cuda-13.3/bin:${PATH}"

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Copy source code with non-root ownership
COPY --chown=bot:bot . .

RUN uv python install 3.13 \
    && uv python pin 3.13 \
    && uv sync --frozen --extra grounding

# Install Playwright dependencies
RUN sudo uv run playwright install --with-deps chromium
