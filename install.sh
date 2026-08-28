#!/bin/bash
# =============================================================================
#  tmxssh installer — drops the tmxssh tool into the system PATH.
#
#  Usage:
#     curl -fsSL https://raw.githubusercontent.com/Daemon-018/tmxssh/main/install.sh | bash
#     (on Termux)                  or
#     bash install.sh
#
#  Installs tmxssh -> $PREFIX/bin/tmxssh  + config dir in ~/.tmxssh
# =============================================================================

REPO_URL="https://raw.githubusercontent.com/Daemon-018/tmxssh/refs/heads/main"

BOLD=$'\033[1m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'
say(){ printf '%s\n' "$*"; }
ok(){  printf '%s[ OK ]%s %s\n' "$GREEN" "$RESET" "$*"; }
warn(){ printf '%s[ WARN ]%s %s\n' "$YELLOW" "$RESET" "$*"; }
err(){ printf '%s[ ERROR ]%s %s\n' "$RED" "$RESET" "$*" >&2; }
die(){ err "$*"; exit 1; }

# ---------- detect target platform ------------------------------------------
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
if [ -d "$PREFIX/bin" ] && [ -n "$(echo "$PREFIX" | grep -i termux)" ]; then
  IS_TERMUX=1
  DEST="$PREFIX/bin/tmxssh"
else
  IS_TERMUX=0
  # non-Termux unix: install to /usr/local/bin if writable, else ~/.local/bin
  if [ -w /usr/local/bin ] && [ -d /usr/local/bin ]; then
    DEST="/usr/local/bin/tmxssh"
  else
    mkdir -p "$HOME/.local/bin"
    DEST="$HOME/.local/bin/tmxssh"
  fi
fi
CONF_DIR="$HOME/.tmxssh"

say ""
say "  ${BOLD}== tmxssh installer ==${RESET}"
say ""

# ---------- fetch the tool ---------------------------------------------------
say "  -> downloading tmxssh..."
TMPF="$(mktemp)"
if ! curl -fsSL "$REPO_URL/tmxssh" -o "$TMPF" 2>/dev/null; then
  die "download failed. check network or the repo URL."
fi

head -1 "$TMPF" | grep -q 'bash' || die "downloaded file does not look like tmxssh"
chmod +x "$TMPF"

# ---------- install ----------------------------------------------------------
mkdir -p "$(dirname "$DEST")"
if ! install -m 0755 "$TMPF" "$DEST" 2>/dev/null; then
  warn "no permission to write $DEST — trying sudo..."
  sudo install -m 0755 "$TMPF" "$DEST" 2>/dev/null || die "could not install to $DEST"
fi
rm -f "$TMPF"
ok "installed to $DEST"

# ---------- ensure openssh is present ----------------------------------------
if [ "$IS_TERMUX" = "1" ]; then
  if ! command -v sshd >/dev/null 2>&1; then
    say "  -> installing openssh..."
    pkg install -y openssh >/dev/null 2>&1 \
      && ok "openssh installed" || warn "run 'pkg install openssh' manually"
  else
    ok "openssh already present"
  fi
else
  if ! command -v sshd >/dev/null 2>&1 && ! command -v ssh >/dev/null 2>&1; then
    warn "OpenSSH server not found. Install openssh-server on this system."
  else
    ok "openssh present"
  fi
fi

# ---------- finish -----------------------------------------------------------
mkdir -p "$CONF_DIR"
say ""
ok "tmxssh is ready!"
say ""
say "  Just run:  ${BOLD}tmxssh${RESET}"
say "  It will start the SSH server in the background and show you"
say "  the command other devices use to connect."
say ""
