# OpenCode-Unlimited

Manage and bypass OpenCode's daily free-message limit from the command line: monitor meter usage, clear stale limit error banners, rotate local device identity, switch providers, and automatically route through fresh network exits.

Supports **Linux**, **macOS**, and **Windows**.

> Nothing here modifies system identifiers, deletes chats, or loses messages.

```bash
opencode-unlimited usage
opencode-unlimited reset ./my-project
```

---

## Installation

### Linux & macOS

```bash
git clone https://github.com/Nirusaki-Malaal/OpenCode-Unlimited.git
cd OpenCode-Unlimited
./install.sh
```

### Windows

```powershell
git clone https://github.com/Nirusaki-Malaal/OpenCode-Unlimited.git
cd OpenCode-Unlimited
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Restart your terminal after installation so `opencode-unlimited` is available on your `PATH`.

### Requirements
- **Node.js 22.5+** (uses Node's native SQLite engine `node:sqlite`)
- **OpenCode CLI**
- Zero external package dependencies

---

## When You Hit the Message Limit

When OpenCode displays:
```text
You've used today's free messages. They reset at 2:00 AM - 10/27/2026
```

Follow these steps:

1. **Close OpenCode**: Exit the desktop app, TUI, and `opencode serve` if active.
2. **Change your IP**:
   - Reconnect your VPN to a different server location.
   - Toggle phone hotspot.
   - Power-cycle your router for a new ISP lease.
   - Or configure proxy rotation: `opencode-unlimited proxy pool add socks5://...`
   
   Check your current egress IP with `opencode-unlimited block`.
3. **Run the reset**:
   ```bash
   opencode-unlimited reset ./my-project
   ```
   This rotates the local device identity, clears stored limit errors from the SQLite database, re-ids sessions in that folder without losing message history, and switches to the next proxy in your pool if configured.
4. **Re-open OpenCode**: The limit banner is cleared and you are on a fresh allocation.

---

## Commands

| Command | Description |
|---|---|
| `opencode-unlimited usage` | Current meter state and time until 00:00 UTC reset |
| `opencode-unlimited usage -check` | Meter check with a live probe message |
| `opencode-unlimited block` | Egress IP blocks seen today and refusal status |
| `opencode-unlimited block check` | Check if current egress IP block is usable |
| `opencode-unlimited reset` | Rotate device ID, clear stored errors, and verify DB |
| `opencode-unlimited reset <path>` | Full reset including session re-ID for specified folder |
| `opencode-unlimited reset <path> --dry` | Preview reset actions without writing changes |
| `opencode-unlimited reset <path> --keep-ids` | Rotate device ID without altering session IDs |
| `opencode-unlimited identity` | Show current virtual device ID and generation |
| `opencode-unlimited identity rotate` | Mint a fresh virtual device identity |
| `opencode-unlimited identity restore` | Remove virtual device ID (leaves system files untouched) |
| `opencode-unlimited sessions [path]` | List sessions, IDs, folders, and history sizes |
| `opencode-unlimited reid <session-id>` | Mint fresh ID for a specific session |
| `opencode-unlimited reid <path>` | Re-ID all sessions under a directory |
| `opencode-unlimited reid <path> --dry` | Preview session re-ID changes |
| `opencode-unlimited model` | List available providers and free models |
| `opencode-unlimited model <spec>` | Switch current directory to specified provider/model |
| `opencode-unlimited model <target> <spec>` | Switch a session ID or folder to specified provider/model |
| `opencode-unlimited clear [path]` | Strip stored `provider.free-limit` errors |
| `opencode-unlimited verify` | Verify session database integrity |
| `opencode-unlimited verify --fix` | Repair detected database inconsistencies |
| `opencode-unlimited status` | Full status: runtime, identity, plugin, network, and ledger |
| `opencode-unlimited doctor` | Environment diagnostics (Node, SQLite, curl, service) |
| `opencode-unlimited version` | Tool and detected OpenCode version |
| `opencode-unlimited on \| off` | Enable or disable the header identity plugin |
| `opencode-unlimited proxy set <url>` | Route OpenCode through `socks5://` or `http://` |
| `opencode-unlimited proxy off` | Restore direct connection |
| `opencode-unlimited proxy pool add <url>` | Add a proxy to the auto-rotation pool |
| `opencode-unlimited proxy next` | Rotate to next pooled proxy immediately |
| `opencode-unlimited warp on\|off\|rotate` | Manage Cloudflare WARP proxy routing |
| `opencode-unlimited run <args...>` | Run OpenCode CLI with automatic rotation on limit hit |
| `opencode-unlimited uninstall` | Cleanly remove slash commands, plugin, and state |

### OpenCode Slash Commands

All core commands can also be run directly from the OpenCode chat prompt:

```text
/opencode-unlimited
/opencode-unlimited:reset ./my-project
/opencode-unlimited:identity rotate
/opencode-unlimited:block
/opencode-unlimited:usage
/opencode-unlimited:reid ./my-project
/opencode-unlimited:model openrouter/deepseek/deepseek-v4.1-flash
/opencode-unlimited:clear ./my-project
```

---

## How the Rate Limit Works

OpenCode's free-tier rate limits are tracked by **egress IP address block** per UTC calendar day:
- **IPv4**: Evaluated per `/32` (single address)
- **IPv6**: Evaluated per `/64` prefix
- **Reset time**: Strictly **00:00 UTC** daily

The limit is not bound to a user account, project, or machine hardware:
- Changing accounts or project names does not reset the quota.
- Changing egress network or rotating to an alternative model provider (via `opencode-unlimited model`) avoids the bottleneck.

---

## Proxy Pool Management

You can configure proxy rotation for automatic switching during `reset`:

```bash
# Add proxies to pool (SOCKS5 or HTTP)
opencode-unlimited proxy pool add socks5://127.0.0.1:1080
opencode-unlimited proxy pool add http://proxy.example.com:8080

# View current pool
opencode-unlimited proxy status

# Step to next proxy manually
opencode-unlimited proxy next
```

SOCKS5 proxies automatically connect through a lightweight local proxy bridge. Proxies are applied exclusively to OpenCode's background service environment—never system-wide.

---

## What `reset` Modifies

1. **Virtual Device Identity**: Generates a local virtual device ID stored in `~/.config/opencode/unlimited-identity.json`. It never touches `/etc/machine-id` or system registries.
2. **Stored Limit Errors**: Removes leftover `provider.free-limit` error records in OpenCode's SQLite database and restores session completion status.
3. **Session IDs**: Re-indexes session IDs in the specified folder with full database transactional integrity. All chat histories and messages are preserved.
4. **Egress Route**: Cycles to the next proxy in your pool if configured.
5. **Egress Ledger**: Queries and caches the active egress IP to verify network transition.
6. **Database Integrity**: Verifies database constraints and fixes dangling references or duplicate project records.

---

## Troubleshooting

- **Usage says block is spent but prompts work**: Longer sessions replay prior context, using more token calls per prompt. A spent notification on heavy chats may still allow shorter prompts to pass.
- **Limit banner persists after running `clear`**: Restart the OpenCode client to reload session state from disk.
- **`reset` reports `ip unchanged`**: The VPN, proxy, or hotspot assigned the same IP. Change server location or network and rerun `reset`.
- **Sessions command displays nothing for a directory**: Run `opencode-unlimited doctor` to check detected database paths. Directory matching is case-insensitive.

---

## Disclaimer

For educational and research purposes only. Not affiliated with, endorsed by, or supported by OpenCode or partners. Use responsibly and in compliance with applicable terms of service.
