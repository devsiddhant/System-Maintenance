#!/bin/bash

set -euo pipefail

# Load .env file
ENV_FILE="$HOME/update/.env"
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
else
  echo "⚠️ .env file missing. Telegram notifications won't work." >&2
fi


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="$SCRIPT_DIR/update.log"
MAX_LOGS=5

# Rotate logs within the script folder
for ((i=MAX_LOGS-1; i>=1; i--)); do
  if [[ -f "$LOGFILE.$i" ]]; then
    mv "$LOGFILE.$i" "$LOGFILE.$((i+1))"
  fi
done
[[ -f "$LOGFILE" ]] && mv "$LOGFILE" "$LOGFILE.1"

# Begin new log
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
{
  echo "===== Update started at $TIMESTAMP ====="
  echo "🛠 Starting Arch system maintenance..."

  if command -v yay &> /dev/null; then
    echo "📦 Updating with yay..."
    yay -Syu --noconfirm
  fi

  echo "🧹 Removing orphaned packages..."
  yay -Rns $(pacman -Qdtq) --noconfirm 2>/dev/null || true

  echo "🧼 Cleaning caches..."
  sudo pacman -Sc --noconfirm
  yay -Sc --noconfirm
  if command -v paru &> /dev/null; then paru -Sc --noconfirm; fi

  if command -v flatpak &> /dev/null; then
    echo "📦 Updating Flatpak..."
    flatpak update -y
  fi

  if command -v brew &> /dev/null; then
    echo "🍺 Updating Homebrew..."
    brew update && brew upgrade && brew cleanup
  fi

  echo "✅ Update completed at $(date)"
} >> "$LOGFILE" 2>&1

# OPTIONAL: Telegram/email notification can still be added here



# Send notification message
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
  -d chat_id="$TELEGRAM_CHAT_ID" \
  -d text="✅ Arch update completed. See attached log." \
  -d parse_mode="Markdown" > /dev/null

# Send the log file as a document
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendDocument" \
  -F chat_id="$TELEGRAM_CHAT_ID" \
  -F document=@"$LOGFILE" > /dev/null

# Read the log contents
LOG_TEXT=$(cat "$LOGFILE")

# Send it as a message (split if too long)
MAX_MSG_LENGTH=4000  # Telegram limit is 4096 chars
if [ ${#LOG_TEXT} -le $MAX_MSG_LENGTH ]; then
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    --data-urlencode text="$LOG_TEXT" \
    -d parse_mode="Markdown" > /dev/null
else
  # Split and send in chunks if needed
  split_msg() {
    echo "$LOG_TEXT" | fold -w $MAX_MSG_LENGTH | while read -r chunk; do
      curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        --data-urlencode text="$chunk" \
        -d parse_mode="Markdown" > /dev/null
    done
  }
  split_msg
fi

