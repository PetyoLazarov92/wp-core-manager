# Changelog

### v1.0.0 (2026-11-04)
* **wpcore:** one shared, read-only core per WordPress version in `/var/www/wp-cores`, linked into each local site: `sudo wpcore add 6.8`, `link`, `switch`, `unlink`, `remove-core` (refused while a site uses it), `list`, `sites`, `status`, and `available` for the versions on wordpress.org
* **wpcore:** a switch reloads PHP-FPM or Apache so OPcache drops the old core, and `wpcore wp <site> ...` runs WP-CLI for one site, with Bash tab completion for every command
* **Installer:** one line installs wpcore: `curl -fsSL https://webtimeless.cloud/wpcore-manager.sh | sudo bash` downloads the newest release's `wpcore`, checks it against its `.sha256`, puts it in `/usr/local/bin` in one step and offers `wpcore init`
* **Installer:** `--version v1.0.0` installs a given release, and `--dry-run` downloads and checks it without installing anything
* **Repo:** releases: every `vX.Y.Z` tag publishes `wpcore`, `wpcore.sha256` and `install.sh` as a GitHub release, its notes from this file; agent rules and skills in `AGENTS.md`, `.cursor/rules/` and `.cursor/skills/`
