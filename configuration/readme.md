# RustDesk Relay Server Setup (DevI9 + Lap01)

**Last Updated**: October 18, 2025

## Overview
- **DevI9**: Hosts `hbbs`/`hbbr` (relay server) and is the remote desktop target.
- **Lap01**: Client connecting to DevI9.
- **Purpose**: Document RustDesk relay setup to prevent config loss during updates.

## DevI9 Configuration
- **IP Address**: `192.168.254.149` (verify with `ipconfig`)
- **RustDesk Version**: 1.4.2 (plan update to 1.4.3)
- **Server Path**: `C:\rustdesk-server\`
- **Services**:
  - `hbbs.exe`: ID server (port 21116)
  - `hbbr.exe`: Relay server (port 21117)
- **Key Files**:
  - Public Key: `id_ed25519.pub` (committed to Git)
  - Private Key: `id_ed25519` (committed, keep secure)
- **Client Settings**:
  - ID Server: `127.0.0.1:21116`
  - Relay Server: `127.0.0.1:21117` (or blank)
  - Key: [Paste contents of `id_ed25519.pub` here]
  - RustDesk ID: [Note DevI9’s ID here]
- **Firewall**:
  - Allow TCP/UDP 21114-21119: `netsh advfirewall firewall add rule name="RustDesk" dir=in action=allow protocol=TCP localport=21114-21119`
- **Logs**: `C:\rustdesk-server\log\hbbs.log` or `C:\Users\YourUser\.rustdesk\log\hbbs.log`

## Lap01 Configuration
- **RustDesk Version**: 1.4.3
- **Client Settings**:
  - ID Server: `192.168.254.149:21116`
  - Relay Server: `192.168.254.149:21117` (or blank)
  - Key: [Same as DevI9’s `id_ed25519.pub`]
- **Logs**: `%APPDATA%\RustDesk\log`

## Update Process
1. **Before Updating RustDesk**:
   - Backup `C:\rustdesk-server\` (copy to `C:\Backup\RustDesk\YYYY-MM-DD`).
   - Save `id_ed25519` and `id_ed25519.pub` to Git or backup.
   - On Lap01, screenshot or note Network settings (`%APPDATA%\RustDesk\config\RustDesk.toml`).
2. **After Updating**:
   - Restore `id_ed25519*` to `C:\rustdesk-server\` if overwritten.
   - Reapply Lap01 settings from this README.
   - Restart `hbbs.exe`/`hbbr.exe` in `C:\rustdesk-server\`.
   - Test connection: Lap01 > DevI9’s RustDesk ID.
3. **Verify**:
   - Check `hbbs` running: `wmic process where name='hbbs.exe' get executablepath`
   - Confirm ports: `netstat -an | findstr 21116`
   - Ping DevI9 from Lap01: `ping 192.168.254.149`

## Troubleshooting
- **No Connection**:
  - Verify DevI9’s IP: `ipconfig`.
  - Check key match: Compare `id_ed25519.pub` on both clients.
  - Test `hbbs`: `netstat -an | findstr 21116` on DevI9.
  - Logs: Check `C:\rustdesk-server\log\hbbs.log` or `%APPDATA%\RustDesk\log`.
- **Key Mismatch**:
  - Regenerate: `cd C:\rustdesk-server && hbbs -k _`
  - Update both clients with new `id_ed25519.pub`.
- **Firewall**: Reapply rules if blocked.

Add the README to Git:
bashgit add README.md
git commit -m "Add RustDesk setup documentation"
git push origin main