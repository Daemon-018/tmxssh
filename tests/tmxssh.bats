#!/usr/bin/env bats
# Tests for the tmxssh CLI. Run with: bats tests/

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO_ROOT/tmxssh"

  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export TMXSSH_HOME="$TEST_HOME/.tmxssh"
  export PREFIX="$TEST_HOME/prefix"
  export COLUMNS=80
  mkdir -p "$TMXSSH_HOME" "$PREFIX/etc/ssh" "$TEST_HOME/bin"

  # Deterministic stand-ins for host tools the script shells out to.
  cat > "$TEST_HOME/bin/ip" <<'SH'
#!/usr/bin/env bash
cat <<'OUT'
1: lo: <LOOPBACK,UP> mtu 65536
    inet 127.0.0.1/8 scope host lo
2: wlan0: <BROADCAST,UP> mtu 1500
    inet 192.168.1.42/24 brd 192.168.1.255 scope global wlan0
    inet 192.0.0.9/24 scope global secondary
OUT
SH
  cat > "$TEST_HOME/bin/ifconfig" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  chmod +x "$TEST_HOME/bin/ip" "$TEST_HOME/bin/ifconfig"
  export PATH="$TEST_HOME/bin:$PATH"

  # shellcheck source=../tmxssh
  source "$SCRIPT"
}

teardown() {
  rm -rf "$TEST_HOME"
}

# ---------- load_config ----------

@test "load_config reads a valid port" {
  printf 'port=2222\n' > "$CONF_FILE"
  load_config
  [ "$SSH_PORT" = "2222" ]
}

@test "load_config missing file is not an error" {
  rm -f "$CONF_FILE"
  run load_config
  [ "$status" -eq 0 ]
  [ -z "${SSH_PORT:-}" ]
}

@test "load_config never evaluates config values (command injection)" {
  cat > "$CONF_FILE" <<EOF
port=2222
EVIL=\$(touch "$TEST_HOME/PWNED")
SSH_PORT=9999
EOF
  load_config
  [ "$SSH_PORT" = "2222" ]
  [ ! -e "$TEST_HOME/PWNED" ]
}

@test "load_config rejects non-numeric and out-of-range ports" {
  printf 'port=abc\n' > "$CONF_FILE"
  run load_config
  [ "$status" -eq 0 ]
  [ -z "${SSH_PORT:-}" ]
  [[ "$output" == *"invalid port"* ]]

  printf 'port=70000\n' > "$CONF_FILE"
  run load_config
  [ "$status" -eq 0 ]
  [ -z "${SSH_PORT:-}" ]
  [[ "$output" == *"out-of-range port"* ]]
}

@test "load_config handles CRLF line endings" {
  printf 'port=8022\r\n' > "$CONF_FILE"
  load_config
  [ "$SSH_PORT" = "8022" ]
}

# ---------- save_config ----------

@test "save_config creates the config with mode 600" {
  rm -rf "$TMXSSH_HOME"
  SSH_PORT=2200
  run save_config
  [ "$status" -eq 0 ]
  [ -f "$CONF_FILE" ]
  [ "$(cat "$CONF_FILE")" = "port=2200" ]
  # BSD stat uses -f, GNU stat uses -c; accept either.
  mode="$(stat -c '%a' "$CONF_FILE" 2>/dev/null || stat -f '%Lp' "$CONF_FILE")"
  [ "$mode" = "600" ]
}

@test "save_config defaults the port when unset" {
  unset SSH_PORT
  run save_config
  [ "$status" -eq 0 ]
  [ "$(cat "$CONF_FILE")" = "port=$DEFAULT_PORT" ]
}

# ---------- get_ssh_port ----------

@test "get_ssh_port prefers the saved config" {
  printf 'port=2022\n' > "$CONF_FILE"
  run get_ssh_port
  [ "$output" = "2022" ]
}

@test "get_ssh_port reads sshd_config when no config exists" {
  rm -f "$CONF_FILE"
  printf 'Port 2201\n' > "$PREFIX/etc/ssh/sshd_config"
  run get_ssh_port
  [ "$output" = "2201" ]
}

@test "get_ssh_port falls back to the default port" {
  rm -f "$CONF_FILE" "$PREFIX/etc/ssh/sshd_config"
  run get_ssh_port
  [ "$output" = "$DEFAULT_PORT" ]
}

# ---------- cmd_port ----------

@test "cmd_port stores a valid port" {
  cmd_port 2223
  [ "$(cat "$CONF_FILE")" = "port=2223" ]
  [ "$SSH_PORT" = "2223" ]
}

@test "cmd_port normalises leading zeros" {
  run cmd_port 08022
  [ "$status" -eq 0 ]
  [ "$(cat "$CONF_FILE")" = "port=8022" ]
}

@test "cmd_port rejects non-numeric input" {
  run cmd_port abc
  [ "$status" -ne 0 ]
  [[ "$output" == *"port must be a number"* ]]
  [ ! -f "$CONF_FILE" ]
}

@test "cmd_port rejects out-of-range ports" {
  run cmd_port 0
  [ "$status" -ne 0 ]
  [[ "$output" == *"out of range"* ]]

  run cmd_port 65536
  [ "$status" -ne 0 ]
  [[ "$output" == *"out of range"* ]]

  run cmd_port 99999999999999999999
  [ "$status" -ne 0 ]
  [[ "$output" == *"out of range"* ]]
}

@test "cmd_port without an argument prints usage" {
  run cmd_port ""
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage: tmxssh port"* ]]
}

# ---------- helpers ----------

@test "rep repeats a glyph" {
  run rep x 4
  [ "$output" = "xxxx" ]
}

@test "banner shows the current version" {
  run banner
  [ "$status" -eq 0 ]
  [[ "$output" == *"OPENSSH NEON SERVER v$TMXSSH_VERSION"* ]]
}

@test "get_lan_ips drops loopback and 192.0.0.x addresses" {
  run get_lan_ips
  [ "$status" -eq 0 ]
  [ "$output" = "192.168.1.42" ]
}

@test "ssh_running reflects pgrep's exit status" {
  cat > "$TEST_HOME/bin/pgrep" <<'SH'
#!/usr/bin/env bash
exit 1
SH
  chmod +x "$TEST_HOME/bin/pgrep"
  run ssh_running
  [ "$status" -ne 0 ]

  cat > "$TEST_HOME/bin/pgrep" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  chmod +x "$TEST_HOME/bin/pgrep"
  run ssh_running
  [ "$status" -eq 0 ]
}

# ---------- password marker ----------

@test "ensure_password does nothing when the marker exists" {
  touch "$TMXSSH_HOME/.pwset"
  run ensure_password
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "ensure_password sets the marker after a successful passwd" {
  cat > "$TEST_HOME/bin/passwd" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  chmod +x "$TEST_HOME/bin/passwd"

  run ensure_password
  [ "$status" -eq 0 ]
  [ -f "$TMXSSH_HOME/.pwset" ]
  [[ "$output" == *"password set"* ]]
}

# ---------- CLI integration ----------

@test "tmxssh --version prints the version" {
  run "$SCRIPT" --version
  [ "$status" -eq 0 ]
  [[ "$output" == *"tmxssh $TMXSSH_VERSION"* ]]
}

@test "tmxssh help lists every command" {
  run "$SCRIPT" help
  [ "$status" -eq 0 ]
  for cmd in start stop restart status info setpass port qr version help; do
    [[ "$output" == *"$cmd"* ]]
  done
}

@test "sourcing the script does not run main" {
  run bash -c 'source "$1"' _ "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
