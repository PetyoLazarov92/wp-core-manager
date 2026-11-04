# wp-core-manager

`wpcore`, a single Bash script that keeps each WordPress version once, in a
shared cores folder, and links local sites to it: `wp-admin`, `wp-includes`
and the root PHP files are symlinks to the version's core, `wp-load.php` is a
copy, and `wp-content` and `wp-config.php` stay the site's own. Switching a
site's version swaps its links and reloads PHP. Its home page is
`https://webtimeless.cloud/wpcore-manager/`; devmagic-panel uses it too.

## Layout

- `wpcore`: the whole tool, installed as `/usr/local/bin/wpcore`. Reads
  `/etc/wpcore.conf` (`CORES_DIR`, `SITES_DIR`, `SITE_PREFIX`, `WP_CLI`, `PHP`,
  `APACHE_USER`), which `sudo wpcore init` writes.
- `install.sh`: the one-line installer. It downloads a release's `wpcore`,
  checks it against its `.sha256` and installs it; it runs as root
  (`curl ... | sudo bash`).
- `VERSION`: the version, read by the release workflow.
- `.github/workflows/check.yml`: syntax, shellcheck and the installer against
  a local release, on every push and pull request.
- `.github/workflows/release.yml`: on a `vX.Y.Z` tag, the same checks, then a
  GitHub release with `wpcore`, `wpcore.sha256` and `install.sh`, its notes
  from `CHANGELOG.md`.

## Commands

```bash
bash -n wpcore install.sh               # syntax
shellcheck -x install.sh                # the installer, no warnings
shellcheck -S error wpcore              # the tool, held at error level
bash install.sh --dry-run               # download and check the newest release
sudo bash install.sh --version v1.0.0   # install a given release
```

## Rules

1. **devmagic-panel depends on it.** The panel ships a copy of `wpcore` in its
   `scripts/bin/wpcore`, allows it in its sudoers rule, and reads the same
   `/etc/wpcore.conf` and cores folder. Commands, their arguments, the config
   keys and the layout of a linked site are its interface: change them only
   in a major version, and tell the user the panel's copy needs the same
   change.
2. **Only released code installs.** `install.sh` installs a release's `wpcore`
   checked against its `.sha256`, never a branch. A release comes only from a
   pushed `vX.Y.Z` tag through `release.yml`.
3. **Version and changelog with every change**, once per session: `VERSION`,
   the README badge and a `CHANGELOG.md` section (see
   `.cursor/rules/versioning.mdc`).
4. **Scripts pass shellcheck.** `install.sh` and new code pass `shellcheck -x`
   with no warnings; `wpcore` is held at error level until it is cleaned up.
5. **Never touch a site's own files.** `wp-content`, `wp-config.php` and
   anything not created by wpcore stay as they are; a core still in use is
   never removed.
6. **Made-up names only.** Examples, tests, comments, docs, the changelog and
   commit messages use made-up names (`local.acme.test`, `local.shop.test`),
   never a real client, project, company or person, including the sites on
   this machine.
7. **No em dashes in new text**: output, docs, comments, commit messages. Use a
   comma, a colon, or two sentences. Older text keeps its own until it is
   rewritten.

## Commit messages

`type(scope): lowercase imperative summary` on one line. No body, no trailing
period. Types are `feat`, `fix`, `chore`, `refactor`, `docs`. Join multiple
concerns with `; `. Suggest the message, commit only when asked. See the
`wt-commit-message` skill for scopes.

## Detail

Conventions live in `.cursor/rules/` (`shell-scripts.mdc`, `versioning.mdc`,
`user-facing-copy.mdc`) and workflows in `.cursor/skills/`
(`wt-commit-message`, `wt-release`), linked from `.claude/skills/`.
