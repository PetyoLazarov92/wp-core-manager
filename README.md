# wpcore — WordPress Multi-Core Manager

![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![Shell: Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash&logoColor=white)
![Platform: Linux](https://img.shields.io/badge/Platform-Linux-FCC624?logo=linux&logoColor=black)
![Requires Root](https://img.shields.io/badge/Requires-sudo-red)
![WP-CLI Compatible](https://img.shields.io/badge/WP--CLI-Compatible-21759B?logo=wordpress&logoColor=white)

A **single Bash script** that lets one server host **dozens of WordPress sites while sharing a small set of versioned WordPress cores** stored in a central directory. Switch any site between core versions in seconds, with zero downtime and automatic OPcache flushing.

---

## Table of Contents

- [How It Works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Commands](#commands)
- [Usage Examples](#usage-examples)
- [Architecture](#architecture)
- [The Smart wp-load Dispatcher](#the-smart-wp-load-dispatcher)
- [Bash Tab Completion](#bash-tab-completion)
- [Contributing](#contributing)
- [License](#license)

---

## How It Works

Instead of every site shipping its own full WordPress core (~25 MB), `wpcore` maintains a set of **shared, read-only core directories** (e.g. `/var/www/wp-cores/6.7.1/`). Each site gets:

| Path | What it is |
|---|---|
| `wp-admin` → symlink | Points to `CORES_DIR/<version>/wp-admin/` |
| `wp-includes` → symlink | Points to `CORES_DIR/<version>/wp-includes/` |
| `*.php` root files → symlinks | Point to the matching file in the core |
| `wp-load.php` → **real file** | Copied from the core so `__DIR__` resolves correctly |
| `wp-content/` → **real dir** | Always site-local, never shared |
| `wp-config.php` → **real file** | Never touched by wpcore |

Switching a site from WordPress 6.6.2 to 6.7.1 is as simple as:

```bash
sudo wpcore switch local.mysite.com 6.7.1
```

`wpcore` removes the old symlinks, creates new ones pointing at the new core, and reloads PHP-FPM (or Apache) to flush the OPcache — all in under a second.

---

## Prerequisites

| Dependency | Notes |
|---|---|
| **Bash 4+** | Ships with every modern Linux distro |
| **wget** | Used to download WordPress tarballs |
| **tar** | Unpacking downloads |
| **systemctl** | OPcache reload (Apache / PHP-FPM) |
| **WP-CLI** *(optional)* | Used by the `wp` sub-command and `update-db` prompt |
| **PHP** *(optional)* | Only needed when running WP-CLI via wpcore |

---

## Installation

### Quick Install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/PetyoLazarov92/wp-core-manager/main/install.sh | sudo bash
```

This will:
1. Download `wpcore` to `/usr/local/bin/wpcore`
2. Make it executable
3. Prompt you to run `wpcore init` to create the config file and install Bash completion

### Manual Install

```bash
sudo curl -fsSL https://raw.githubusercontent.com/PetyoLazarov92/wp-core-manager/main/wpcore \
    -o /usr/local/bin/wpcore
sudo chmod +x /usr/local/bin/wpcore
sudo wpcore init
```

### Clone and Install

```bash
git clone https://github.com/PetyoLazarov92/wp-core-manager.git
cd wp-core-manager
sudo cp wpcore /usr/local/bin/wpcore
sudo chmod +x /usr/local/bin/wpcore
sudo wpcore init
```

---

## Configuration

`wpcore init` creates `/etc/wpcore.conf` with sensible defaults:

```bash
# /etc/wpcore.conf

CORES_DIR="/var/www/wp-cores"   # Shared core versions live here
SITES_DIR="/var/www"            # Root of all site directories
SITE_PREFIX="local."            # Only directories matching this prefix are treated as sites
WP_CLI="wp"                     # Path or name of the WP-CLI binary
PHP="php"                       # PHP binary used to invoke WP-CLI
APACHE_USER="www-data"          # Web server user (file ownership)
```

Edit this file to match your server layout before adding any cores.

---

## Commands

### Core Management

| Command | Description |
|---|---|
| `sudo wpcore add <version>` | Download and install a WordPress core version |
| `sudo wpcore remove-core <version>` | Remove a core version (blocked if a site is using it) |
| `wpcore list` | List all installed core versions |

### Site Management

| Command | Description |
|---|---|
| `sudo wpcore link <site> <version>` | Link a site to a core for the first time |
| `sudo wpcore switch <site> <version>` | Switch a site to a different core version |
| `sudo wpcore unlink <site>` | Remove all core symlinks from a site |
| `wpcore sites` | List all sites and their current core version |

### WP-CLI Proxy

| Command | Description |
|---|---|
| `wpcore wp <site> <command…>` | Run any WP-CLI command for a specific site |

### Other

| Command | Description |
|---|---|
| `wpcore status` | Show cores + sites overview |
| `sudo wpcore init` | Create config, directories, and install Bash completion |
| `sudo wpcore install-completion` | (Re)install Bash tab completion |
| `wpcore help` | Print help |

---

## Usage Examples

```bash
# 1. Initialize on a fresh server
sudo wpcore init

# 2. Download two WordPress versions
sudo wpcore add 6.6.2
sudo wpcore add 6.7.1

# 3. Link an existing site directory to a core
sudo wpcore link local.mysite.com 6.6.2

# 4. Switch a site to a newer core
sudo wpcore switch local.mysite.com 6.7.1

# 5. See everything at once
wpcore status

# 6. Run WP-CLI through wpcore
wpcore wp local.mysite.com plugin list
wpcore wp local.mysite.com core update-db

# 7. Remove a core that is no longer used
sudo wpcore remove-core 6.6.2
```

---

## Architecture

```
/var/www/
├── wp-cores/                         ← CORES_DIR (shared, read-only)
│   ├── 6.6.2/
│   │   ├── wp-admin/
│   │   ├── wp-includes/
│   │   ├── wp-load.php               ← smart dispatcher (auto-installed)
│   │   ├── wp-load.php.dist          ← original WP file (backup)
│   │   └── index.php, wp-login.php … ← other core PHP files
│   └── 6.7.1/
│       └── …
│
├── local.site-a.com/                 ← individual site
│   ├── wp-admin      → ../wp-cores/6.7.1/wp-admin   (symlink)
│   ├── wp-includes   → ../wp-cores/6.7.1/wp-includes (symlink)
│   ├── index.php     → ../wp-cores/6.7.1/index.php   (symlink)
│   ├── wp-login.php  → ../wp-cores/6.7.1/wp-login.php (symlink)
│   ├── wp-load.php                   ← real copy (ABSPATH = this dir)
│   ├── wp-config.php                 ← site-owned, never touched
│   └── wp-content/                   ← site-owned, never touched
│
└── local.site-b.com/                 ← another site, different version
    ├── wp-admin      → ../wp-cores/6.6.2/wp-admin   (symlink)
    └── …
```

---

## The Smart `wp-load` Dispatcher

Every WordPress core installed by `wpcore` gets a custom `wp-load.php` placed in the core root. This dispatcher solves the edge case where a tool resolves symlinks before `include`-ing `wp-load.php`, ending up inside `CORES_DIR` instead of the site root.

Detection order:
1. `$_SERVER['DOCUMENT_ROOT']` — web requests (Apache / Nginx vhost root)
2. `getcwd()` — WP-CLI (sets cwd to `--path`)
3. `debug_backtrace()` — unusual call stacks / nested includes

Once the correct site directory is located, the dispatcher delegates to that site's own real `wp-load.php` copy, ensuring `ABSPATH` is always the site root.

---

## Bash Tab Completion

`wpcore init` (and `wpcore install-completion`) installs a completion script to `/etc/bash_completion.d/wpcore`.

```bash
sudo wpcore install-completion
source /etc/bash_completion.d/wpcore   # activate in the current shell
```

After that, tab-completion works for all commands, site names, and installed core versions:

```
$ wpcore switch local.<TAB>        # auto-completes site names
$ wpcore switch local.mysite.com <TAB>  # auto-completes installed core versions
```

---

## Contributing

Contributions, bug reports, and feature requests are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

Please follow existing code style (Bash strict mode, `set -euo pipefail`, meaningful comments).

---

## License

Released under the [MIT License](LICENSE).

Copyright © 2026 Petyo Lazarov
