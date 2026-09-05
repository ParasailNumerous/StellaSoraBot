# Docker/Podman

Container runs **StellaSoraBot + Stella Sora game (Wine/Proton-GE) + GroundingDINO (CUDA)** together. Based on `StellaSoraBotv2.sh`.

## Base

- `nvidia/cuda:12.8.0-cudnn-runtime-ubuntu24.04` (Ubuntu 24.04 — 22.04 nearing EOL; 26.04 has no official CUDA image yet, switch `FROM` to `ubuntu26.04` when NVIDIA publishes it)
- `pyproject.toml` pins `pytorch-cu128` + Python 3.13 (`uv python pin 3.13`), matching CUDA 12.8. GroundingDINO hardcodes `cuda:0` with no CPU fallback (`character_info/char_sprite_face.py:45`).

## Requirements

- NVIDIA GPU + driver with CUDA 12.8 support, `nvidia-container-toolkit` installed, Docker with `runtime: nvidia` / CDI.
- ~15 GB image (CUDA + dotnet-sdk-8.0 + Wine + Proton-GE + Chromium), plus game data (~10-20 GB) in `stella-wine` volume.
- Private `fkStellaSora` unpacker — **not baked into public image** (legal). Provide at runtime (see below).
- `user-passwords.py` + `user-config.py` edits for wiki uploads (pywikibot).

## Build & run

`docker` can be used instead of `podman`.

Before starting, ensure you edit `user-passwords.py` & `user-config.py`, and add the folder for fkStellaSora in `docker-compose.yml`.

```bash
run0 podman image trust set -t accept docker.io/nvidia/cuda

podman compose build
podman compose run --gpus all stellasora  # interactive shell (default CMD)

# first run inside container — install game (interactive, needs DISPLAY or xvfb):
wine ~/StellaSora_EN_Launcher.exe
# or: $PROTON_GE run ~/StellaSora_EN_Launcher.exe
# install to C:\YostarGames, launch game, pass prologue + voice download
# then from repo root:
uv run -m unpack.unpack_main
uv run -m main
uv run -m main2
```

Single-shot: `podman compose run --gpus all stellasora uv run -m main`

## Private vendor

```yaml
volumes:
  - /path/to/private/fkStellaSora:/home/bot/StellaSoraBot/vendor/fkStellaSora:ro
```

Without it, `entrypoint.sh` warns and `unpack` fails. Other `vendor/*` (StellaSoraData, wwiser, groundingdino) are cloned/pulled at runtime; `vendor/weights/groundingdino_swint_ogc.pth` auto-downloads (also retried at entry).

## Game

Launcher URL `StellaSora_EN_Gamelauncher-1.6.0-setup.exe` (see `StellaSoraBotv2.sh:82`) is downloaded at build to `~/StellaSora_EN_Launcher.exe`. `vc_redist.x86.exe` + `winetricks vcrun2019` preinstalled. `stella-wine` named volume persists `WINEPREFIX` + game install.

Display: container sets `DISPLAY=${DISPLAY:-:0}` for host X passthrough; falls back to `xvfb` if headless.

## Updating

Rebuild when CUDA/PyTorch or `StellaSoraBotv2.sh` changes. Ubuntu 26.04: change `FROM` tag when `nvidia/cuda:*-ubuntu26.04` exists.
