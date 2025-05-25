#!/bin/bash
set -euo pipefail

BASE_DIR="$HOME/update"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/update_$(date +'%Y%m%d_%H%M%S').log"
MAX_LOGS=5

mkdir -p "$LOG_DIR"

echo "Updating Alpine packages with apk..." | tee -a "$LOG_FILE"
sudo apk update >> "$LOG_FILE" 2>&1
sudo apk upgrade >> "$LOG_FILE" 2>&1

echo "Updating Flatpak packages..." | tee -a "$LOG_FILE"
flatpak update -y >> "$LOG_FILE" 2>&1

if command -v brew &> /dev/null; then
  echo "Updating Homebrew packages..." | tee -a "$LOG_FILE"
  brew update >> "$LOG_FILE" 2>&1
  brew upgrade >> "$LOG_FILE" 2>&1
  brew cleanup >> "$LOG_FILE" 2>&1
fi

echo "Cleaning apk cache..." | tee -a "$LOG_FILE"
sudo apk cache clean >> "$LOG_FILE" 2>&1

echo "Cleaning Flatpak cache..." | tee -a "$LOG_FILE"
flatpak uninstall --unused -y >> "$LOG_FILE" 2>&1

# Rotate logs
cd "$LOG_DIR"
ls -1tr update_*.log | head -n -"$MAX_LOGS" | xargs -r rm --

# Telegram notification
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendDocument" \
    -F chat_id="${TELEGRAM_CHAT_ID}" \
    -F document=@"${LOG_FILE}" \
    -F caption="Alpine update log $(basename "$LOG_FILE")" >> "$LOG_FILE" 2>&1
fi

echo "Update completed at $(date)" | tee -a "$LOG_FILE"

