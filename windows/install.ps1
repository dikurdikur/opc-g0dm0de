# OpenClaw Plug & Play — Windows Installer
# Requires: PowerShell 5.1+ (Run as Administrator)
# Installs: Ollama, OpenClaw, configures bots, pulls models

$ErrorActionPreference = "Stop"
$script:Dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:SharedDir = Join-Path (Split-Path -Parent $script:Dir) "shared"

# ─── Helpers ───
function Log { param($msg) Write-Host "[*] $msg" -ForegroundColor Cyan }
function Ok  { param($msg) Write-Host "[✓] $msg" -ForegroundColor Green }
function Warn{ param($msg) Write-Host "[!] $msg" -ForegroundColor Yellow }
function Err { param($msg) Write-Host "[✗] $msg" -ForegroundColor Red; exit 1 }

# ─── Admin Check ───
function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Err "Please run PowerShell as Administrator (right-click → Run as Administrator)"
}

# ─── Detect OS Info ───
function Get-OSInfo {
    $os = Get-CimInstance Win32_OperatingSystem
    Log "Detected: $($os.Caption) $($os.Version)"
    return $os
}

# ─── Check Dependencies ───
function Test-Deps {
    Log "Checking dependencies..."
    
    $needs = @()
    
    # Check Node.js (need 22+)
    $nodeVer = $null
    try { $nodeVer = (& node -v 2>$null).Trim() } catch {}
    
    if ($nodeVer) {
        $major = [int]($nodeVer -replace 'v','').Split('.')[0]
        if ($major -lt 22) {
            Warn "Node.js $nodeVer found, need 22+. Will upgrade..."
            $needs += "nodejs"
        } else {
            Ok "Node.js $nodeVer OK"
        }
    } else {
        $needs += "nodejs"
    }
    
    # Check git
    try { 
        $gitVer = (& git --version 2>$null).Trim()
        Ok "Git found: $gitVer"
    } catch {
        $needs += "git"
    }
    
    # Check curl
    try {
        $null = & curl --version 2>$null | Select-Object -First 1
        Ok "curl found"
    } catch {
        $needs += "curl"
    }
    
    return $needs
}

# ─── Install via Chocolatey or winget ───
function Install-Packages {
    param([string[]]$Packages)
    
    Log "Installing: $($Packages -join ', ')"
    
    # Try winget first (Windows 10 20H1+)
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    
    foreach ($pkg in $Packages) {
        switch ($pkg) {
            "nodejs" {
                if ($winget) {
                    Log "Installing Node.js via winget..."
                    & winget install --id OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
                } else {
                    # Download installer directly
                    Log "Downloading Node.js installer..."
                    $url = "https://nodejs.org/dist/v22.11.0/node-v22.11.0-x64.msi"
                    $out = "$env:TEMP\nodejs.msi"
                    Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
                    Log "Installing Node.js..."
                    Start-Process msiexec.exe -ArgumentList "/i `"$out`" /quiet /norestart" -Wait
                    Remove-Item $out -ErrorAction SilentlyContinue
                }
                
                # Refresh PATH
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            }
            "git" {
                if ($winget) {
                    & winget install --id Git.Git --accept-package-agreements --accept-source-agreements
                } else {
                    $url = "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.2/Git-2.47.1.2-64-bit.exe"
                    $out = "$env:TEMP\git-installer.exe"
                    Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
                    Start-Process $out -ArgumentList "/VERYSILENT /NORESTART" -Wait
                    Remove-Item $out -ErrorAction SilentlyContinue
                }
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            }
            "curl" {
                # curl is built into Windows 10 1803+, but just in case
                if ($winget) {
                    & winget install --id curl.curl --accept-package-agreements --accept-source-agreements
                }
            }
        }
    }
    
    Ok "Packages installed"
}

# ─── Install Ollama ───
function Install-OllamaWin {
    $ollamaPath = Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama.exe"
    
    if (Test-Path $ollamaPath) {
        $ver = & $ollamaPath --version 2>$null
        Ok "Ollama already installed: $ver"
        return
    }
    
    Log "Installing Ollama for Windows..."
    $url = "https://ollama.com/download/OllamaSetup.exe"
    $out = "$env:TEMP\OllamaSetup.exe"
    
    Log "Downloading Ollama..."
    Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
    
    Log "Running Ollama installer..."
    Start-Process $out -ArgumentList "/SILENT" -Wait
    Remove-Item $out -ErrorAction SilentlyContinue
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    # Verify
    if (Test-Path $ollamaPath) {
        Ok "Ollama installed successfully"
    } else {
        Warn "Ollama installed but not found in PATH. May need to restart terminal."
    }
}

# ─── Sync Model Catalog ───
function Sync-ModelCatalog {
    Log "Syncing model catalog..."
    
    $catalogFile = Join-Path $script:SharedDir "model-catalog.json"
    New-Item -ItemType Directory -Path (Split-Path $catalogFile) -Force | Out-Null
    
    $catalog = @{
        updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        sources = @{
            cloud = "https://ollama.com/search?c=cloud"
            local = "https://ollama.com/library"
        }
        models = @{
            recommended = @{
                id = "kimi-k2.6:cloud"
                name = "Kimi K2.6 (Cloud)"
                provider = "ollama"
                tags = @("cloud", "multilingual", "long-context")
                description = "Moonshot AI's Kimi K2.6 via Ollama cloud"
            }
            cloud = @()
            local = @(
                @{id="llama3.2"; name="Llama 3.2"; size="2B-70B"; tags=@("meta","general")}
                @{id="qwen2.5"; name="Qwen 2.5"; size="0.5B-72B"; tags=@("alibaba","multilingual")}
                @{id="mistral"; name="Mistral"; size="7B"; tags=@("mistral-ai","general")}
                @{id="gemma2"; name="Gemma 2"; size="2B-27B"; tags=@("google","general")}
                @{id="phi4"; name="Phi-4"; size="14B"; tags=@("microsoft","reasoning")}
            )
        }
    }
    
    $catalog | ConvertTo-Json -Depth 10 | Set-Content $catalogFile
    Ok "Model catalog saved"
}

# ─── Pull Default Model ───
function Pull-DefaultModel {
    Log "Checking for kimi-k2.6:cloud..."
    
    $ollama = Get-Command ollama -ErrorAction SilentlyContinue
    if (-not $ollama) {
        Warn "Ollama not in PATH. You may need to restart your terminal and run: ollama pull kimi-k2.6:cloud"
        return
    }
    
    $list = & ollama list 2>$null
    if ($list -match "kimi-k2.6") {
        Ok "Model kimi-k2.6 already available"
        return
    }
    
    Log "Pulling kimi-k2.6:cloud (this may take a while)..."
    & ollama pull kimi-k2.6:cloud
    
    if ($LASTEXITCODE -eq 0) {
        Ok "Model pulled successfully"
    } else {
        Warn "Could not pull model. Run manually: ollama pull kimi-k2.6:cloud"
    }
}

# ─── Install OpenClaw ───
function Install-OpenClaw {
    $oc = Get-Command openclaw -ErrorAction SilentlyContinue
    if ($oc) {
        Ok "OpenClaw already installed"
        return
    }
    
    Log "Installing OpenClaw via npm..."
    & npm install -g openclaw
    
    if ($LASTEXITCODE -eq 0) {
        Ok "OpenClaw installed"
    } else {
        Err "Failed to install OpenClaw. Is Node.js 22+ installed?"
    }
}

# ─── Configure OpenClaw ───
function Configure-OpenClaw {
    Log "Configuring OpenClaw workspace..."
    
    $workspace = Join-Path $env:USERPROFILE ".openclaw"
    New-Item -ItemType Directory -Path $workspace -Force | Out-Null
    
    # Config directory
    $configDir = Join-Path $workspace "config"
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    
    # Write gateway.yaml template
    $configFile = Join-Path $configDir "gateway.yaml"
    if (-not (Test-Path $configFile)) {
        @"
# OpenClaw Gateway Configuration
# Generated by OpenClaw Plug & Play

controlUi:
  dangerouslyDisableDeviceAuth: true

agents:
  - id: main
    name: NanoBot
    model: ollama/kimi-k2.6:cloud
    channel: discord
    discord:
      token: `${DISCORD_TOKEN}
      guilds: []
      allowDMs: false
      allowGroups: true
      allowedUsers: []
    telegram:
      token: `${TELEGRAM_TOKEN}
    ollama:
      host: http://localhost:11434
"@ | Set-Content $configFile
        Ok "Config template written"
    }
    
    # Write .env template
    $envFile = Join-Path $workspace ".env"
    @"
# OpenClaw Environment Variables
# DISCORD_TOKEN=your_discord_bot_token
# TELEGRAM_TOKEN=your_telegram_bot_token
# ADMIN_DISCORD_ID=your_discord_user_id
"@ | Set-Content $envFile
    
    Ok "Workspace ready at $workspace"
}

# ─── Prompt for Tokens ───
function Prompt-Config {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  OpenClaw Plug & Play — Configuration" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    
    $discordToken = Read-Host "Discord Bot Token (leave blank to skip)"
    $telegramToken = Read-Host "Telegram Bot Token (leave blank to skip)"
    $adminId = Read-Host "Your Discord User ID (admin/owner)"
    $allowDMs = Read-Host "Allow DMs? [y/N]"
    $allowGroups = Read-Host "Allow group chats? [Y/n]"
    
    # Save to .env
    $envFile = Join-Path $env:USERPROFILE ".openclaw\.env"
    $lines = @("# Updated by OpenClaw Plug & Play")
    if ($discordToken) { $lines += "DISCORD_TOKEN=$discordToken" }
    if ($telegramToken) { $lines += "TELEGRAM_TOKEN=$telegramToken" }
    if ($adminId) { $lines += "ADMIN_DISCORD_ID=$adminId" }
    $lines | Set-Content $envFile
    
    # Update config
    $configFile = Join-Path $env:USERPROFILE ".openclaw\config\gateway.yaml"
    $content = Get-Content $configFile -Raw
    
    if ($discordToken) {
        $content = $content -replace '\$\{DISCORD_TOKEN\}', $discordToken
    }
    if ($telegramToken) {
        $content = $content -replace '\$\{TELEGRAM_TOKEN\}', $telegramToken
    }
    if ($adminId) {
        $content = $content -replace 'allowedUsers: \[\]', "allowedUsers: [$adminId]"
    }
    
    if ($allowDMs -match '^[Yy]') {
        $content = $content -replace 'allowDMs: false', 'allowDMs: true'
    }
    if ($allowGroups -match '^[Nn]') {
        $content = $content -replace 'allowGroups: true', 'allowGroups: false'
    }
    
    $content | Set-Content $configFile
    Ok "Configuration saved!"
}

# ─── Discord Helper ───
function Show-DiscordHelper {
    $perms = "274877910080"
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  Discord Bot Setup" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Go to: https://discord.com/developers/applications"
    Write-Host "2. Create New Application → Bot"
    Write-Host "3. Enable Privileged Gateway Intents:"
    Write-Host "   ✓ MESSAGE CONTENT INTENT"
    Write-Host "   ✓ SERVER MEMBERS INTENT"
    Write-Host "   ✓ PRESENCE INTENT"
    Write-Host "4. Copy your Bot Token (reset if needed)"
    Write-Host "5. Get Application ID from General Information"
    Write-Host ""
    Write-Host "Invite URL (replace YOUR_CLIENT_ID):"
    Write-Host "https://discord.com/oauth2/authorize?client_id=YOUR_CLIENT_ID&permissions=$perms&integration_type=0&scope=bot+applications.commands"
    Write-Host ""
}

# ─── Telegram Helper ───
function Show-TelegramHelper {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  Telegram Bot Setup" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Message @BotFather on Telegram"
    Write-Host "2. Send /newbot and follow prompts"
    Write-Host "3. Copy the HTTP API token"
    Write-Host ""
}

# ─── Final Status ───
function Show-Status {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "  OpenClaw Plug & Play — Setup Complete" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ollama:     $(if (Get-Command ollama -EA SilentlyContinue) { & ollama --version } else { 'Check after restart' })"
    Write-Host "OpenClaw:   $(if (Get-Command openclaw -EA SilentlyContinue) { 'Installed' } else { 'Check after restart' })"
    Write-Host "Workspace:  $env:USERPROFILE\.openclaw"
    Write-Host "Config:     $env:USERPROFILE\.openclaw\config\gateway.yaml"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Set your bot tokens in .env file"
    Write-Host "  2. Review config\gateway.yaml"
    Write-Host "  3. Start OpenClaw: openclaw gateway start"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  ollama list              # List models"
    Write-Host "  ollama pull <model>      # Pull a model"
    Write-Host "  openclaw status          # Check status"
    Write-Host ""
    Write-Host "NOTE: Restart your terminal for PATH changes to take effect." -ForegroundColor Yellow
}

# ─── Main ───
function Main {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║   OpenClaw Plug & Play — Windows Setup  ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $os = Get-OSInfo
    $needs = Test-Deps
    if ($needs.Count -gt 0) {
        Install-Packages -Packages $needs
    }
    Install-OllamaWin
    Sync-ModelCatalog
    Pull-DefaultModel
    Install-OpenClaw
    Configure-OpenClaw
    Prompt-Config
    Show-DiscordHelper
    Show-TelegramHelper
    Show-Status
}

Main
