# ⚡ OpenClaw Plug & Play

One-command setup for [OpenClaw](https://github.com/openclaw/openclaw) + [Ollama](https://ollama.com). From zero to running bot in minutes — with full system-level control.

[![Linux](https://img.shields.io/badge/Linux-✓-brightgreen?style=flat-square&logo=linux)](./linux)
[![Windows](https://img.shields.io/badge/Windows-✓-blue?style=flat-square&logo=windows)](./windows)
[![Docker](https://img.shields.io/badge/Docker-WIP-yellow?style=flat-square&logo=docker)](./docker)

📖 **[Documentation Site](https://jlaiii.github.io/openclaw-plug-and-play)**

---

## Quick Start

### 🐧 Linux

```bash
git clone https://github.com/jlaiii/openclaw-plug-and-play.git
cd openclaw-plug-and-play/linux
chmod +x install.sh
./install.sh
```

**Supported:** Ubuntu 20.04+, Debian 11+, Fedora 35+, Arch, Manjaro

### 🪟 Windows

```powershell
git clone https://github.com/jlaiii/openclaw-plug-and-play.git
cd openclaw-plug-and-play\windows
.\install.ps1
```

**Requires:** Windows 10/11, PowerShell 5.1+ (Run as Administrator)

---

## What It Does

1. **Detects OS** — Identifies distro and package manager
2. **Installs dependencies** — Node.js 22+, git, curl (if missing)
3. **Configures NOPASSWD sudo** — Passwordless `sudo` for non-interactive automation
4. **Installs Ollama** — Official installer, starts service
5. **Pulls default model** — `kimi-k2.6:cloud` with retry logic
6. **Installs OpenClaw** — `npm install -g openclaw`
7. **Configures workspace** — Creates `~/.openclaw/` with defaults
8. **Prompts for tokens** — Discord, Telegram, admin ID + extra whitelist users
9. **Enables both channels** — Discord + Telegram active
10. **Sets up systemd service** — Runs OpenClaw as root, auto-starts on boot
11. **Verifies system access** — Tests shell, packages, network, file write
12. **Prints setup guide** — Discord intents, invite URL, BotFather steps

---

## Features

| Feature | Description |
|---------|-------------|
| 🚀 **One-Command Setup** | Single script installs everything and configures bots |
| 🔒 **Whitelist Security** | DMs enabled but restricted to whitelisted Discord IDs only |
| 🤖 **Dual Channels** | Discord + Telegram both configured and active |
| ☁️ **Cloud & Local Models** | Defaults to `kimi-k2.6:cloud`, syncs catalog from ollama.com |
| 🖥️ **Cross-Platform** | Native scripts for Linux and Windows |
| ⚙️ **System-Level Control** | Passwordless `sudo`, systemd service as root, full system access |
| 🔄 **Idempotent** | Safe to run multiple times — detects existing installs and skips duplicates |
| 📝 **Multi-User Whitelist** | Add multiple Discord users during install or edit config later |

---

## Discord Security Model

| Feature | Setting | How It Works |
|---------|---------|--------------|
| **DMs** | `allowDMs: true` | ✅ Enabled — only whitelisted Discord IDs can DM |
| **Groups** | `allowGroups: true` | ✅ Enabled — works in all servers (or whitelisted guild) |
| **Whitelist** | Multi-user | You + any extra users added during setup |
| **Guild lock** | Optional | Restrict to specific server, or leave open |
| **Token storage** | `.env` file | Auto-.gitignored, never committed |
| **Device auth** | Disabled | `dangerouslyDisableDeviceAuth: true` for local use |

Add more whitelisted users anytime by editing `~/.openclaw/config/gateway.yaml`:

```yaml
discord:
  allowedUsers: [123456789, 987654321, 555555555]
```

---

## System-Level Setup

The Linux installer configures full non-interactive system control:

- **Passwordless sudo** — Creates `/etc/sudoers.d/99-openclaw-$USER` with `NOPASSWD: *** checks for duplicates, validates syntax
- **Systemd service** — `openclaw.service` runs as `root`, auto-starts on boot
- **Access verification** — Tests shell execution, package manager, network, file write
- **Idempotent** — Won't duplicate sudoers entries or overwrite existing service configs

Start/stop the service:

```bash
sudo systemctl start openclaw     # Start now
sudo systemctl stop openclaw      # Stop
sudo systemctl enable openclaw    # Enable on boot (already done)
sudo systemctl status openclaw    # Check status
```

---

## After Install

### 1. Set Your Tokens

Edit `~/.openclaw/.env` (Linux) or `%USERPROFILE%\.openclaw\.env` (Windows):

```env
DISCORD_TOKEN=your_discord_bot_token
TELEGRAM_TOKEN=your_telegram_bot_token
ADMIN_DISCORD_ID=your_discord_user_id
```

### 2. Start OpenClaw

```bash
# Manual start (foreground)
openclaw gateway start

# Or use systemd (background, root privileges)
sudo systemctl start openclaw
```

### 3. Verify

```bash
openclaw status          # Gateway status
ollama list              # Installed models
sudo systemctl status openclaw  # Service status
```

---

## Model Catalog

The installer syncs models from [ollama.com/search?c=cloud](https://ollama.com/search?c=cloud). Switch models by editing `~/.openclaw/config/gateway.yaml`:

```yaml
# Cloud models (no local GPU needed)
model: ollama/kimi-k2.6:cloud
model: ollama/qwen2.5:cloud

# Local models (requires GPU/CPU)
model: ollama/llama3.2
model: ollama/mistral
model: ollama/phi4
```

Pull new models: `ollama pull <model>`

---

## Roadmap

- [ ] Docker Compose deployment
- [ ] Windows service auto-start
- [ ] TUI wizard (whiptail/dialog)
- [ ] Auto-update script
- [ ] Backup/restore config
- [ ] Interactive model picker

---

## Contributing

Open an issue or PR: [github.com/jlaiii/openclaw-plug-and-play](https://github.com/jlaiii/openclaw-plug-and-play)

---

Built by [@jlaiii](https://github.com/jlaiii) · Not affiliated with OpenClaw or Ollama
