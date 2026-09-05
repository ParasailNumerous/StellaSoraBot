#!/usr/bin/env bash
set -euo pipefail

# ponytail: idempotent init — re-runs safely, skips done steps

# fix fkStellaSora volume mount (private, legal restriction)
if [ ! -d vendor/fkStellaSora ]; then
  echo "[entrypoint] vendor/fkStellaSora not mounted — unpack will fail until you mount it:" >&2
  echo "  -v /path/to/private/fkStellaSora:/home/bot/StellaSoraBot/vendor/fkStellaSora:ro" >&2
fi

# GroundingDINO weights retry
if [ ! -s vendor/weights/groundingdino_swint_ogc.pth ]; then
  echo "[entrypoint] downloading GroundingDINO weights..."
  mkdir -p vendor/weights
  wget -q https://github.com/IDEA-Research/GroundingDINO/releases/download/v0.1.0-alpha/groundingdino_swint_ogc.pth \
    -O vendor/weights/groundingdino_swint_ogc.pth || echo "[entrypoint] weights download failed" >&2
fi

# ensure GroundingDINO cloned (char_sprite_face.py also clones, but do it early)
if [ ! -d vendor/groundingdino ]; then
  echo "[entrypoint] cloning GroundingDINO (needed for face detection)..."
  git clone -q https://github.com/IDEA-Research/GroundingDINO.git vendor/groundingdino || true
fi

# init Wine prefix on first run
if [ ! -f "$WINEPREFIX/system.reg" ]; then
  echo "[entrypoint] initializing Wine prefix at $WINEPREFIX ..."
  wineboot --init || true; wineserver --wait || true
  # deps the launcher needs (StellaSoraBotv2.sh: vcredist2019 + webview2)
  winetricks -q vcrun2019 2>/dev/null || echo "[entrypoint] vcrun2019 install skipped" >&2
fi

# install game if not yet installed (C:\YostarGames)
if [ ! -d "$STELLA_SORA_DIR/StellaSora_Data" ]; then
  echo "[entrypoint] Stella Sora not installed at \$STELLA_SORA_DIR ($STELLA_SORA_DIR)" >&2
  echo "  Run inside container: wine ~/StellaSora_EN_Launcher.exe" >&2
  echo "  Or with Proton-GE: \$PROTON_GE run ~/StellaSora_EN_Launcher.exe" >&2
  echo "  Complete launcher install to C:\\YostarGames, launch game, pass prologue / voice download." >&2
fi

# source uv env if present
[ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"

exec "$@"
