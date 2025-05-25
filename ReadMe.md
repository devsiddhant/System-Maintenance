
# Arch Update Automation Script

Automate your Arch Linux system updates using `yay` (covers official + AUR packages), Flatpak, and Homebrew, with cache cleaning and Telegram notifications.  
Runs silently in the background and logs all actions.

# If you are using any other disribution, look at the Distros folder and copy the script for your distribution in th update folder and delete other files.
For example: If you are using Linux Mint, copy the UpdateDebian.sh in the update folder then delte Distros folder, delete original update.sh and rename UpdateDebian.sh into update.sh. The guide below is regarding arch based distros. But the above steps should guarantee the working on any other distro.
Note: This was tested in EndeavourOS. THe scripts have not been tested in any other OS. 
---

## Features

- Weekly automated updates using `yay`
- Cleans package caches (`pacman`, `yay`, `paru`)
- Sends detailed logs via Telegram (file + text message)
- Keeps last 5 logs only
- Runs as a `systemd` user timer
- Simple configuration with `.env` to keep secrets safe

---

## Getting Started
### PreRequisites(Otional): Passwordless sudo for convenience (Increases risk so make sure to only enable this if you have the device with you at all times)

# Passwordless sudo Setup for Update Script

To run the update script without being prompted for your password, configure passwordless sudo using one of the methods below.

---

## 1. Passwordless sudo for a Specific Command (Recommended)

Edit your sudoers file safely with:

```bash
sudo visudo
```

Add this line (replace `yourusername` and the full path to `update.sh`):

```
yourusername ALL=(ALL) NOPASSWD: /home/yourusername/update/update.sh
```

This lets your user run just the update script without a password.

---

## 2. Passwordless sudo System-wide (Less Secure)

To disable password prompts for **all** sudo commands for your user, add:

```
yourusername ALL=(ALL) NOPASSWD: ALL
```

**Warning:** This reduces security and should be used with caution.

---

Remember to replace `yourusername` with your actual username.

---


### 1. Create a Telegram Bot and Get Your Bot Token

1. Open Telegram app or [Telegram Web](https://web.telegram.org).
2. Search for **@BotFather** and start a chat.
3. Send the command: `/newbot`
4. Follow prompts to name your bot and get a **bot username**.
5. After creation, BotFather will give you a **bot token** that looks like:

   ```
   123456789:ABCdefGhIJKlmNoPQRstuVWXyz
   ```

   Save this token — you’ll need it for the script.

---

### 2. Get Your Telegram Chat ID

1. Open Telegram and search for your **new bot's username**.
2. Send any message (e.g., `/start`) to your bot.
3. Open your browser and visit the URL below, replacing `YOUR_BOT_TOKEN` with your actual token:

   ```
   https://api.telegram.org/botYOUR_BOT_TOKEN/getUpdates
   ```

4. Look for `"chat": { "id": YOUR_CHAT_ID, ... }` in the JSON response.
5. Copy the number from `"id"` — this is your **chat ID**.

> **Tip:** If the response is empty, make sure you sent a message to your bot first.

---

### 3. Setup Your Update Script

1. Clone or download this repository.
2. Navigate to the `update` folder.
3. Create a `.env` file to store your Telegram credentials:

   ```bash
   nano .env
   ```

   Paste the following, replacing with your token and chat ID:

   ```env
   TELEGRAM_BOT_TOKEN=123456789:ABCdefGhIJKlmNoPQRstuVWXyz
   TELEGRAM_CHAT_ID=123456789
   ```

4. Save and close the file.
5. Make sure `.env` is included in `.gitignore` to prevent pushing secrets to GitHub.

---

### 4. Run the Script Manually (Optional)

```bash
cd ~/update
chmod +x update.sh
./update.sh
```

Check your Telegram for the update logs.

---

### 5. Setup Systemd Timer for Weekly Automation

Run these commands:

```bash
mkdir -p ~/.config/systemd/user

# Create service file
cat > ~/.config/systemd/user/update.service <<EOF
[Unit]
Description=Weekly Arch System Update

[Service]
Type=oneshot
WorkingDirectory=%h/update
ExecStart=%h/update/update.sh
EOF

# Create timer file
cat > ~/.config/systemd/user/update.timer <<EOF
[Unit]
Description=Run Arch Update Script Weekly

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Reload systemd daemon, enable & start timer
systemctl --user daemon-reexec
systemctl --user daemon-reload
systemctl --user enable --now update.timer
```

Verify timer with:

```bash
systemctl --user list-timers
```

---

## Keeping Your Telegram Bot Token Safe

- **Never commit** your `.env` file to Git or push it to public repositories.
- Use `.gitignore` to exclude `.env`:

  ```
  echo ".env" >> .gitignore
  ```

- If your token leaks, **revoke and regenerate** it via [@BotFather](https://t.me/BotFather) immediately.
- Store sensitive credentials locally or use secure vaults for production setups.

---

## Troubleshooting

- **Empty `getUpdates` response:** Make sure you sent a message to your bot.
- **No Telegram messages:** Check your bot token and chat ID are correct.
- **Systemd timer not running:** Ensure `systemctl --user` commands are run under your user, and systemd user services are enabled.

---

## License

MIT License

---

## Contributions

Feel free to submit issues or pull requests to improve this script!

---

Made with ❤️ for Arch Linux users.
