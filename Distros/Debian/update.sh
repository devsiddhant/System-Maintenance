#!/bin/bash

set -euo pipefail

# Paths
BASE_DIR="$HOME/update"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/update_$(date +'%Y%m%d_%H%M%S').log"
MAX_LOGS=5

mkdir -p "$LOG_DIR"

# Update system packages with apt
echo "Updating system packages with apt..." | tee -a "$LOG_FILE"
sudo apt update >> "$LOG_FILE" 2>&1
sudo apt -y upgrade >> "$LOG_FILE" 2>&1
sudo apt -y autoremove >> "$LOG_FILE" 2>&1
sudo apt -y autoclean >> "$LOG_FILE" 2>&1

# Update flatpak packages
echo "Updating Flatpak packages..." | tee -a "$LOG_FILE"
flatpak update -y >> "$LOG_FILE" 2>&1

# Update Homebrew packages (if installed)
if command -v brew &> /dev/null; then
  echo "Updating Homebrew packages..." | tee -a "$LOG_FILE"
  brew update >> "$LOG_FILE" 2>&1
  brew upgrade >> "$LOG_FILE" 2>&1
fi

# Clear apt cache
echo "Cleaning apt cache..." | tee -a "$LOG_FILE"
sudo apt -y clean >> "$LOG_FILE" 2>&1

# Clear flatpak cache (optional)
echo "Cleaning Flatpak cache..." | tee -a "$LOG_FILE"
flatpak uninstall --unused -y >> "$LOG_FILE" 2>&1

# Clear Homebrew cache (optional)
if command -v brew &> /dev/null; then
  echo "Cleaning Homebrew cache..." | tee -a "$LOG_FILE"
  brew cleanup >> "$LOG_FILE" 2>&1
fi

# Rotate logs: keep only last $MAX_LOGS
cd "$LOG_DIR"
ls -1tr update_*.log | head -n -"$MAX_LOGS" | xargs -r rm --

# Telegram notification (if enabled)
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
  echo "Sending Telegram log file..." | tee -a "$LOG_FILE"
  # Send log file only
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendDocument" \
    -F chat_id="${TELEGRAM_CHAT_ID}" \
    -F document=@"${LOG_FILE}" \
    -F caption="Mint/Debian update log $(basename "$LOG_FILE")" >> "$LOG_FILE" 2>&1
fi

echo "Update completed at $(date)" | tee -a "$LOG_FILE"

