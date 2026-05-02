# OpenClaw Plug & Play

One-command setup for OpenClaw + Ollama. Clone, run, done.

## Quick Start

### Linux
```bash
git clone https://github.com/yourname/openclaw-plug-and-play.git
cd openclaw-plug-and-play/linux
chmod +x install.sh
./install.sh
```

### Windows (PowerShell Admin)
```powershell
git clone https://github.com/yourname/openclaw-plug-and-play.git
cd openclaw-plug-and-play\windows
.\install.ps1
```

### Docker (Coming Soon)
```bash
docker compose up -d
```

## What It Does

1. **Installs Ollama** — Downloads, installs, starts service
2. **Pulls models** — Default: `kimi-k2.6:cloud` + catalog sync from ollama.com
3. **Installs OpenClaw** — Node.js 22+, npm, openclaw global
4. **Configures bots** — Discord + Telegram tokens, whitelists, permissions
5. **Starts services** — Ollama + OpenClaw running

## Project Structure

```
openclaw-plug-and-play/
├── linux/          # Linux install scripts
├── windows/        # Windows PowerShell scripts
├── docker/         # Docker Compose setup (WIP)
├── shared/         # Templates, configs, model catalog
└── docs/           # Documentation
```

## Requirements

- **Linux:** Ubuntu 20.04+, Debian 11+, Fedora 35+, Arch
- **Windows:** Windows 10/11, PowerShell 5.1+ (Admin)
- **Docker:** Docker 20.10+, Docker Compose 2.0+

## Model Catalog

Auto-syncs available models from [ollama.com/search?c=cloud](https://ollama.com/search?c=cloud).

## License

MIT
