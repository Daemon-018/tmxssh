# tmxssh

**tmxssh** is a free, open-source tool for **Termux (Android)** that starts an
OpenSSH **server** on your device in the background, so other devices —
**laptops, phones, tablets** — can SSH **into** your Termux over your local
network.

One command after install, and it shows you exactly what to type on the other
device to connect.

> Made for Termux by [Daemon-018](https://github.com/Daemon-018). MIT licensed.

---

## What it does

- **Auto-starts `sshd`** on your Termux in the background.
- **Auto-installs `openssh`** if it isn't already there.
- **Guides you through setting an SSH login password** on first run.
- **Shows the exact `ssh` command** (IP + port + user) that other devices use
  to connect to you.
- Lets you **change the port** and **reset the password** easily.
- **LAN only** — other devices must be on the same network as your phone.

---

## Install (one command)

On **Termux**, run:

```bash
curl -fsSL https://raw.githubusercontent.com/Daemon-018/tmxssh/main/install.sh | bash
```

This installs the `tmxssh` command straight into your system path.

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

## Uninstall

```bash
rm -f "$PREFIX/bin/tmxssh"   # on Termux: $PREFIX is /data/data/com.termux/files/usr
pkill sshd                   # stop the server if running
```

Config is stored in `~/.tmxssh/` — delete that too if you want a clean slate.

---

## Requirements

- **Termux** on Android (works out of the box).
- An active network connection.
- Other devices on the **same network** to connect to you.

---

## License

[MIT](LICENSE) — free to use, modify, and share.
