# OpenClaw Plug & Play — Setup Script Project Plan

## Goal
A single GitHub repo that a Linux user can clone and run one script to get a fully-working OpenClaw instance with Discord + Telegram bots configured, minimal prompts, secure defaults.

---

## Repo Name Candidates
- `openclaw-plug-and-play`
- `openclaw-quickstart`
- `openclaw-oneclick`
- `openclaw-ez-setup`

**Leaning toward:** `openclaw-plug-and-play`

---

## What the Script Should Do (Phase 1 — Core)

### 1. Environment Prep
- Detect OS (Ubuntu/Debian/Fedora/Arch) and install deps
  - Node.js 22+, npm, git, curl
  - Optional: Docker if we add a containerized path later

### 2. OpenClaw Install
- Clone official OpenClaw repo or install via npm (`npm install -g openclaw`)
- Create workspace directory at `~/.openclaw`
- Write default `AGENTS.md`, `SOUL.md`, `USER.md`, `TOOLS.md`

### 3. Bot Token Collection (Minimal Prompts)
Prompt user for (only what's needed):
- Discord bot token
- Telegram bot token (optional — skip if not wanted)
- Admin Discord user ID (for whitelist/owner)
- Discord guild/server IDs where the bot should work (optional)
- Whether DMs are allowed (y/n)
- Whether group chats are allowed (y/n)

### 4. Config Generation
Write `gateway.yaml` (or config patch) with:
```yaml
agents:
  - id: main
    model: ollama/kimi-k2.6:cloud   # or let user pick
    channel: discord
    discord:
      token: <discord-token>
      guilds: [<guild-id>]           # whitelist guilds
      allowDMs: false                # or true
      allowedUsers: [<admin-id>]     # DM whitelist
      allowGroups: true
    telegram:
      token: <telegram-token>
```

### 5. Discord Intents & Bot Setup Helper
- Print clear instructions for Discord Developer Portal steps
  - Enable intents (Message Content, Server Members, etc.)
  - Invite URL generator (with correct scopes: bot, applications.commands)
  - Permissions: Send Messages, Read Messages, Embed Links, Add Reactions
- Optionally open browser to portal (if desktop environment detected)

### 6. Telegram Setup Helper
- Print botfather instructions
- Generate webhook or polling URL if needed

### 7. Whitelist / Security Layer
- Implement `allowedUsers` in Discord config (only listed Discord IDs can DM)
- Implement `guilds` whitelist (only respond in specific servers)
- Implement `allowGroups` toggle
- Default to **secure**: DMs off, groups on only if guild listed, admin-only

### 8. First Run & Validation
- Run `openclaw gateway status` check
- Print connection success/failure
- Print how to start: `openclaw gateway start` or systemd service

---

## Phase 2 — Nice to Have

- [ ] Systemd service auto-install (`openclaw.service`)
- [ ] Docker Compose path (alternative to bare-metal)
- [ ] Ollama auto-install + model pull (kimi-k2.6 or llama3)
- [ ] Interactive model picker (local vs cloud)
- [ ] Update script (`./update.sh`) to pull latest OpenClaw
- [ ] Backup/restore config
- [ ] Web UI or TUI wizard (whiptail/dialog)

---

## File Structure

```
openclaw-plug-and-play/
├── README.md
├── install.sh              # Main entry point
├── lib/
│   ├── detect-os.sh        # OS detection & package install
│   ├── install-node.sh     # Node.js install if missing
│   ├── install-openclaw.sh # npm install / git clone
│   ├── config-gen.sh       # Write gateway.yaml from prompts
│   ├── discord-helper.sh   # Invite URL, intent checklist
│   ├── telegram-helper.sh  # BotFather guidance
│   └── security.sh         # Whitelist validation
├── templates/
│   ├── agents.md.tpl
│   ├── soul.md.tpl
│   ├── user.md.tpl
│   └── gateway.yaml.tpl
├── extras/
│   ├── systemd/
│   │   └── openclaw.service
│   └── docker/
│       └── docker-compose.yml
└── tests/
    └── test-install.sh
```

---

## Prompt Style (Minimal Input)

Instead of 20 questions, do one screen at a time:

```
[OpenClaw Plug & Play Setup]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Discord Bot Token: ████████████████████
Telegram Bot Token (Enter to skip):
Your Discord User ID (admin/owner): 796576150474194975
Allow bot to respond in DMs? [y/N]: n
Allow bot in group chats? [Y/n]: y
Guild IDs to whitelist (comma-separated):
> 1499873326523351171
Model provider [ollama/openai/anthropic]: ollama
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Writing config... Done.
Starting OpenClaw... Done.
```

---

## Security Defaults

- `allowDMs: false` by default
- `allowedUsers: [<owner-id>]` if DMs enabled
- `guilds: []` → if empty, allow all guilds; if populated, whitelist only
- No tokens hardcoded in repo, always env vars or config file
- `.gitignore` auto-generated so `gateway.yaml` with tokens never commits

---

## Next Steps

1. **You:** Confirm repo name, pick which Phase 2 items matter
2. **Me:** Create the repo structure locally, write `install.sh` + helpers
3. **Test:** Run on a fresh VM / container
4. **Push:** GitHub repo init, README, release
