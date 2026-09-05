# syntax=docker/dockerfile:1
FROM nvidia/cuda:12.8.0-cudnn-runtime-ubuntu24.04
ARG DEBIAN_FRONTEND=noninteractive

# --- system deps (StellaSoraBotv2.sh + Wine/Proton-GE) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git build-essential wget ffmpeg default-jre \
    ca-certificates cabextract winbind xvfb xauth \
    libvulkan1 libvulkan1:i386 2>/dev/null || true; \
    dpkg --add-architecture i386 && apt-get update && apt-get install -y --no-install-recommends \
    wine64 wine32 winetricks xvfb \
    && rm -rf /var/lib/apt/lists/*

# .NET 8 SDK (StellaSoraBotv2.sh: microsoft prod deb)
RUN wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb \
    && dpkg -i /tmp/packages-microsoft-prod.deb && rm /tmp/packages-microsoft-prod.deb \
    && apt-get update && apt-get install -y --no-install-recommends dotnet-sdk-8.0 \
    && rm -rf /var/lib/apt/lists/*

# non-root user for secureblue (script forbids root)
RUN useradd -m -s /bin/bash bot && usermod -aG audio,video bot
USER bot
WORKDIR /home/bot
ENV HOME=/home/bot \
    PATH=/home/bot/.local/bin:/home/bot/.cargo/bin:$PATH \
    WINEPREFIX=/home/bot/.wine-stella \
    WINEARCH=win64 \
    STELLA_SORA_DIR=/home/bot/.wine-stella/drive_c/YostarGames/StellaSora_EN \
    CUDA_HOME=/usr/local/cuda

# uv (astral.sh)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH=/home/bot/.cargo/bin:$PATH
# ensure uv env on PATH
RUN echo 'source $HOME/.local/bin/env' >> /home/bot/.bashrc || true

# vgmstream-cli (StellaSoraBotv2.sh)
RUN wget -q https://github.com/vgmstream/vgmstream-releases/releases/download/nightly/vgmstream-linux-cli.tar.gz -O /tmp/vgmstream.tar.gz \
    && tar -xzf /tmp/vgmstream.tar.gz -C /tmp && mv /tmp/vgmstream-cli /home/bot/.local/bin/ \
    && rm /tmp/vgmstream.tar.gz

# Proton-GE (latest)
RUN mkdir -p /home/bot/.local/share/proton-ge \
    && ver=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4) \
    && wget -q "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${ver}/${ver}.tar.gz" -O /tmp/proton-ge.tar.gz \
    && tar -xzf /tmp/proton-ge.tar.gz -C /home/bot/.local/share/proton-ge --strip-components=1 2>/dev/null || tar -xzf /tmp/proton-ge.tar.gz -C /tmp && mv /tmp/*GE-Proton* /home/bot/.local/share/proton-ge 2>/dev/null || true \
    && rm /tmp/proton-ge.tar.gz
ENV PROTON_GE=/home/bot/.local/share/proton-ge/proton

# StellaSoraBot
RUN git clone https://github.com/lihaohong6/StellaSoraBot.git /home/bot/StellaSoraBot
WORKDIR /home/bot/StellaSoraBot
RUN uv python pin 3.13 && uv sync --extra grounding
RUN uv run playwright install chromium --with-deps 2>/dev/null || uv run playwright install chromium

# GroundingDINO weights auto-download (skipped if already present via volume)
RUN mkdir -p vendor/weights && \
    wget -q https://github.com/IDEA-Research/GroundingDINO/releases/download/v0.1.0-alpha/groundingdino_swint_ogc.pth \
    -O vendor/weights/groundingdino_swint_ogc.pth || echo "weights download failed — will retry at runtime"

# Wine prefix + game launcher download (installer runs at first container start, not build)
RUN wineboot --init || true; wineserver --wait || true
RUN wget -q https://launcher-pkg-ss-en.yo-star.com/install_pkg/game_launcher/StellaSora_EN/StellaSora_EN_Gamelauncher-1.6.0-setup.exe \
    -O /home/bot/StellaSora_EN_Launcher.exe \
    && wget -q https://aka.ms/vc14/vc_redist.x86.exe -O /home/bot/vc_redist.x86.exe || true

# fkStellaSora is PRIVATE — not baked in. Expected at runtime:
#   -v /path/to/private/fkStellaSora:/home/bot/StellaSoraBot/vendor/fkStellaSora:ro
# entrypoint handles missing vendor gracefully

COPY --chown=bot:bot entrypoint.sh /home/bot/entrypoint.sh
RUN chmod +x /home/bot/entrypoint.sh

WORKDIR /home/bot/StellaSoraBot
ENTRYPOINT ["/home/bot/entrypoint.sh"]
CMD ["/bin/bash"]
