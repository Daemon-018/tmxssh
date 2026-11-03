# tmxssh — One-Command SSH Server for Termux (Android)

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![CI](https://github.com/Daemon-018/tmxssh/actions/workflows/ci.yml/badge.svg)](https://github.com/Daemon-018/tmxssh/actions/workflows/ci.yml)
[![Termux](https://img.shields.io/badge/platform-Termux%20(Android)-00897b.svg)](https://termux.com)
[![Shell](https://img.shields.io/badge/shell-bash-black.svg)](https://www.gnu.org/software/bash/)

**tmxssh** is a free, open-source tool for **Termux (Android)** that starts an
**OpenSSH server** on your device in the background — turning your Android
phone or tablet into a fully accessible **SSH host**. Laptops, other phones
and tablets on the same network can then **SSH into your Termux terminal**
over **LAN** with one simple command.

It's the fastest way to get **remote access to Termux**: auto-installs
`openssh`, guides you through setting a login password, starts `sshd`, and
prints the exact `ssh` command the other device needs — no config files, no
manual port-forwarding.

> Made for Termux by [**Daemon-018**](https://github.com/Daemon-018). MIT licensed. Free & open source.

---

## What it does

- **Auto-starts `sshd`** on your Termux in the background.
- **Auto-installs `openssh`** if it isn't already there.
- **Guides you through setting an SSH login password** on first run (Termux ships with no password).
- **Shows the exact `ssh` command** (IP + port + user) other devices use to connect to you.
- **Prints a scannable QR code** (`tmxssh qr`) so a phone camera grabs the connect command instantly.
- Lets you **change the port** and **reset the password** easily.
- **LAN only** — other devices must be on the same network as your phone.
- **Cyberpunk neon theme** with the `@daemon-018` banner, auto-adapting to your terminal width.

---

## Install (one command)

On **Termux**, run:

```bash
curl -fsSL https://raw.githubusercontent.com/Daemon-018/tmxssh/refs/heads/main/install.sh | bash
```

This installs the `tmxssh` command straight into your system path. Then just
type **`tmxssh`** to start your SSH server.

---

## Usage

Just type:

```bash
tmxssh
```

On first run it will:
1. Make sure `openssh` is installed.
2. Ask you to **set an SSH login password** (one time).
3. Start the SSH server in the background.
4. Print the connection command, e.g.:

```
ssh -p 8022 u0_a123@192.168.1.5
```

Type that on your laptop / other phone / tablet, enter the password you set,
and you're in.

### Subcommands

| Command               | What it does                                   |
|-----------------------|------------------------------------------------|
| `tmxssh`              | auto-start (if needed) + show connect info     |
| `tmxssh start`        | start sshd in background + show info           |
| `tmxssh stop`         | stop sshd                                      |
| `tmxssh restart`      | restart sshd                                   |
| `tmxssh status`       | show running state                             |
| `tmxssh info`         | show IP / port / user again                    |
| `tmxssh setpass`      | set or change the SSH login password           |
| `tmxssh port N`       | change the SSH port (default **8022**)         |
| `tmxssh qr`           | show a scannable QR connect code               |
| `tmxssh version`      | show the installed version                     |
| `tmxssh help`         | show help                                      |

---

## How the other device connects

From a laptop / tablet / another phone (same network):

```bash
ssh -p 8022 <user>@<this-device-ip>
```

- `<user>` is what `tmxssh` prints (your Termux username).
- `<this-device-ip>` is the LAN IP it prints (e.g. `192.168.1.5`).
- Use the password you set with `tmxssh setpass` (or during first run).
- On Termux, the default SSH port is **8022** (not the usual 22).

### Connecting from another Termux / Android phone

Install `openssh` there, then the same `ssh -p 8022 user@ip` command works.

### Connecting from Windows

Use **PowerShell** (OpenSSH built in):

```powershell
ssh -p 8022 user@192.168.1.5
```

---

## Changing the port

```bash
tmxssh port 2222
tmxssh restart
```

Then connect with `ssh -p 2222 user@ip`.

---

## FAQ

**Why does Termux SSH use port 8022?**
Because the standard SSH port 22 is not available on Termux. tmxssh defaults
to **8022** and lets you change it anytime with `tmxssh port N`.

**Can I access my phone from anywhere (the internet)?**
Not out of the box — tmxssh is **LAN only**. For internet access, pair it with a
tunnel (cloudflared / ngrok / pinggy) or use SSH over a VPN.

**Is tmxssh free?**
Yes. 100% free and open source under the MIT license.

**Does it need root?**
No. Runs entirely inside a normal Termux environment.

**How do I change my SSH password?**
`tmxssh setpass`.

---

## Uninstall

```bash
rm -f "$PREFIX/bin/tmxssh"   # on Termux: $PREFIX is /data/data/com.termux/files/usr
pkill sshd                   # stop the server if running
```

Config is stored in `~/.tmxssh/` — delete that too if you want a clean slate.

---

## Development

The script is a single bash file with no runtime dependencies beyond Termux's
own tools. Tests use [bats-core](https://github.com/bats-core/bats-core) and
linting uses [ShellCheck](https://www.shellcheck.net/).

```bash
# Debian / Ubuntu
sudo apt-get install -y bats shellcheck

# Termux
pkg install -y bats shellcheck   # or: npm i -g bats

bash -n tmxssh && bash -n install.sh
shellcheck -x tmxssh install.sh
bats tests/
```

CI runs syntax checks, ShellCheck, and the full bats suite on every push and
pull request. Pushing a tag like `v1.1.0` builds a `.tar.gz` + SHA-256 checksum
and publishes a GitHub release.

### Safety notes

- The config file (`~/.tmxssh/config`) is parsed with a **key allow-list** and
  validated values — it is never `eval`'d, so a tampered file cannot run code.
- The config is written with `0600` permissions.
- The script only auto-runs when executed directly; sourcing it (as the tests
  do) defines functions without starting anything.

---

## Requirements

- **Termux** on Android (works out of the box).
- An active network connection.
- Other devices on the **same network** to connect to you.

---

## Keywords / Topics

`termux` · `ssh` · `openssh` · `android` · `ssh server` · `ssh into android` ·
`termux ssh server` · `remote access` · `lan` · `terminal` · `android ssh` ·
`ssh host` · `termux-tools` · `linux` · `bash`

---

## License

[MIT](LICENSE) — free to use, modify, and share. Crafted by
[@Daemon-018](https://github.com/Daemon-018).
