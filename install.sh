#!/usr/bin/env bash
set -e

NO_PATH=0
WITH_PLUGIN=0

for arg in "$@"; do
  case "$arg" in
    --no-path)
      NO_PATH=1
      ;;
    --with-plugin)
      WITH_PLUGIN=1
      ;;
    *)
      ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$ROOT/bin"
ENTRY="$BIN/opencode-unlimited"
PLUGIN_SRC="$ROOT/plugins/unlimited-shield.js"

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
PLUGIN_DIR="$CONFIG_DIR/plugins"
PLUGIN_DST="$PLUGIN_DIR/unlimited-shield.js"

ok() { echo -e "  \033[32m[+]\033[0m $1"; }
bad() { echo -e "  \033[31m[x]\033[0m $1"; exit 1; }
warn() { echo -e "  \033[33m[!]\033[0m $1"; }
info() { echo -e "      \033[90m$1\033[0m"; }

echo "==> opencode-unlimited install"

# Check required files
for file in \
  "$ENTRY" \
  "$ROOT/lib/proxy-bridge.js" \
  "$ROOT/lib/oc-info.js" \
  "$ROOT/lib/db-tools.js" \
  "$ROOT/lib/session-reid.js" \
  "$ROOT/lib/identity.js" \
  "$ROOT/lib/egress.js" \
  "$ROOT/lib/model-switch.js"; do
  if [ ! -f "$file" ]; then
    bad "missing required file: $file"
  fi
done
ok "files present"

# Ensure binary is executable
chmod +x "$ENTRY"

# Check Node.js
if ! command -v node >/dev/null 2>&1; then
  bad "node not found: session tools and identity helpers require Node.js 22.5+"
fi

NODE_VER=$(node -e 'const [maj, min] = process.versions.node.split(".").map(Number); if (maj < 22 || (maj === 22 && min < 5)) { process.exit(1); } console.log(process.versions.node);' 2>/dev/null || true)
if [ -z "$NODE_VER" ]; then
  bad "Node.js 22.5 or newer is required (found $(node -v 2>/dev/null || echo 'none'))"
fi
ok "node v$NODE_VER"

# Plugin handling
if [ "$WITH_PLUGIN" -eq 1 ]; then
  if [ ! -f "$PLUGIN_SRC" ]; then
    bad "missing plugin: $PLUGIN_SRC"
  fi
  mkdir -p "$PLUGIN_DIR"
  cp "$PLUGIN_SRC" "$PLUGIN_DST"
  ok "plugin deployed: $PLUGIN_DST"
elif [ -f "$PLUGIN_DST" ]; then
  warn "an old plugin copy is present: $PLUGIN_DST"
  info "it rewrites request headers and does not change the quota"
  info "remove it with: opencode-unlimited off"
else
  ok "plugin not installed (it does not change the quota)"
fi

# PATH configuration
if [ "$NO_PATH" -eq 0 ]; then
  case ":$PATH:" in
    *":$BIN:"*)
      info "already on PATH: $BIN"
      ;;
    *)
      DETECTED_RC=""
      if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
        DETECTED_RC="$HOME/.zshrc"
      elif [ -f "$HOME/.bashrc" ]; then
        DETECTED_RC="$HOME/.bashrc"
      elif [ -f "$HOME/.profile" ]; then
        DETECTED_RC="$HOME/.profile"
      fi

      LINE="export PATH=\"$BIN:\$PATH\""
      if [ -n "$DETECTED_RC" ]; then
        if ! grep -q "$BIN" "$DETECTED_RC" 2>/dev/null; then
          echo "" >> "$DETECTED_RC"
          echo "# opencode-unlimited" >> "$DETECTED_RC"
          echo "$LINE" >> "$DETECTED_RC"
          ok "added to PATH in $DETECTED_RC"
          info "run: source $DETECTED_RC (or open a new terminal)"
        else
          info "already referenced in $DETECTED_RC"
        fi
      else
        info "add to your shell configuration:"
        info "$LINE"
      fi
      export PATH="$BIN:$PATH"
      ;;
  esac
fi

# Run install command for slash commands and config
"$ENTRY" install

echo ""
echo -e "  \033[36mnext:\033[0m"
info "opencode-unlimited version    tool plus the detected opencode version"
info "opencode-unlimited usage      what the meter is doing today"
info "opencode-unlimited reset .    new device id, new session ids, nothing lost"
info "opencode-unlimited model      providers you can switch to"
info "opencode-unlimited status     runtime, identity, network, ledger"
info "opencode-unlimited proxy set socks5://127.0.0.1:1080   optional IP path"
echo ""
ok "installed"
