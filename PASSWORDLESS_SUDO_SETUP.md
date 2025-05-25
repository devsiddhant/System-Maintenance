
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
