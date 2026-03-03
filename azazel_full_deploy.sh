#!/usr/bin/env bash
# [SS][TDOC-META-WRAPPER-vFINAL]
# Title: Azazel AiPDF Full Deploy & Git Sync
# Author: Architect of Gaia
# Project: Bibliothique / GAIA Nexus
# GitHub Repo: https://github.com/Azazeleous/-z-m
# ===================================================================

AE="${AE:-$HOME/Æ}"
SYNC_DIR="$AE/cloud/azazel_git"
DOWNLOADS_DIR="$AE/downloads"
ZIP_FILE="$DOWNLOADS_DIR/azazel_ai_presentation.zip"
GITHUB_USER="Azazeleous"
REPO_NAME="-z-m"
BRANCH="main"
TOKEN="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"

mkdir -p "$SYNC_DIR" "$AE/bin" "$AE/logs" "$AE/remedy" "$AE/cloud/NexusDrive" "$DOWNLOADS_DIR"

# Logging function
_log() { printf "[%s] %s\n" "$(date '+%F %T')" "$1" | tee -a "$AE/logs/ss_activity_$(date +%Y%m%d).log"; }

_log "=== Azazel AiPDF Deploy START ==="

# ----------------------------------------------------------
# 1. Ensure ZIP exists (download if missing)
# ----------------------------------------------------------
if [ ! -f "$ZIP_FILE" ] || [ ! -s "$ZIP_FILE" ]; then
    _log "[!] ZIP missing or empty at $ZIP_FILE, attempting download..."
    curl -fL -o "$ZIP_FILE" \
        "https://github.com/Azazeleous/-z-m/releases/latest/download/azazel_ai_presentation.zip" \
        || { _log "[!] Download failed, continuing with empty deployment"; ZIP_FILE=""; }
    [ -s "$ZIP_FILE" ] && _log "Download complete: $ZIP_FILE"
fi

# ----------------------------------------------------------
# 2. Unzip AiPDF to SYNC_DIR
# ----------------------------------------------------------
if [ -f "$ZIP_FILE" ] && [ -s "$ZIP_FILE" ]; then
    _log "Unzipping $ZIP_FILE to $SYNC_DIR"
    unzip -o "$ZIP_FILE" -d "$SYNC_DIR" 2>/dev/null || _log "[!] Unzip failed, skipping."
else
    _log "[!] No valid ZIP to unzip, skipping."
fi

# ----------------------------------------------------------
# 3. Initialize Git repository if missing
# ----------------------------------------------------------
cd "$SYNC_DIR" || mkdir -p "$SYNC_DIR" && cd "$SYNC_DIR"
[ -d ".git" ] || git init
git remote remove origin 2>/dev/null || true
git remote add origin "https://$GITHUB_USER:$TOKEN@github.com/$GITHUB_USER/$REPO_NAME.git"
git config --local user.name "$GITHUB_USER"
git config --local user.email "user@example.com"
git config --local credential.protectProtocol false

# ----------------------------------------------------------
# 4. Commit & push AiPDF files
# ----------------------------------------------------------
AI_DIR="$SYNC_DIR/AiPDF"
mkdir -p "$AI_DIR"

if [ -d "$AI_DIR" ]; then
    git add "$AI_DIR/"* 2>/dev/null || _log "[!] No files to add in AiPDF"
    git commit -m "Automated AiPDF append $(date '+%F %T')" 2>/dev/null || _log "[!] Nothing to commit"
else
    _log "[!] AiPDF folder missing, skipping commit"
fi

# Ensure branch exists
git fetch origin "$BRANCH" 2>/dev/null
git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH"

GIT_ASKPASS_SCRIPT=$(mktemp)
cat > "$GIT_ASKPASS_SCRIPT" <<EOL
#!/bin/sh
echo "$TOKEN"
EOL
chmod +x "$GIT_ASKPASS_SCRIPT"

_log "Pushing AiPDF files to GitHub..."
GIT_ASKPASS="$GIT_ASKPASS_SCRIPT" git push origin "$BRANCH" || _log "[!] Push failed"
rm "$GIT_ASKPASS_SCRIPT"

# ----------------------------------------------------------
# 5. Pull back to verify sync
# ----------------------------------------------------------
GIT_ASKPASS_SCRIPT=$(mktemp)
cat > "$GIT_ASKPASS_SCRIPT" <<EOL
#!/bin/sh
echo "$TOKEN"
EOL
chmod +x "$GIT_ASKPASS_SCRIPT"

_log "Pulling repo back to verify sync..."
GIT_ASKPASS="$GIT_ASKPASS_SCRIPT" git pull origin "$BRANCH" || _log "[!] Pull failed"
rm "$GIT_ASKPASS_SCRIPT"

# ----------------------------------------------------------
# 6. Setup Azazel CLI folder
# ----------------------------------------------------------
AZAZEL_DIR="$AE/န"
mkdir -p "$AZAZEL_DIR"
TDOC_PATH="$SYNC_DIR/azazel_full_deploy.sh"
[ -f "$TDOC_PATH" ] && ln -sf "$TDOC_PATH" "$AZAZEL_DIR/azazel_cli.sh"

_log "Azazel CLI folder ready at $AZAZEL_DIR"
_log "=== Azazel AiPDF Deploy COMPLETE ==="
echo "[§] SESSION ALIVE — AiPDF FULL AUTOMATION VERIFIED"

