#!/usr/bin/env bash
# Installs wpcore from its newest release, or the one given with --version: downloads the
# release's wpcore and its checksum, checks both, and puts wpcore in /usr/local/bin in one step.
# Then it offers to run `wpcore init`, which writes /etc/wpcore.conf.
#
#   curl -fsSL https://webtimeless.cloud/wpcore-manager.sh | sudo bash
#   sudo bash install.sh [--version v1.0.0] [--repo owner/name] [--dry-run]
#
# --dry-run downloads and checks wpcore, then stops; it needs no sudo.
set -euo pipefail

SLUG="${WPCORE_REPO:-PetyoLazarov92/wp-core-manager}"
# Where release files are downloaded from, and where wpcore goes; tests point both at temp folders.
BASE="${WPCORE_DOWNLOAD_BASE:-}"
BIN_DIR="${WPCORE_BIN_DIR:-/usr/local/bin}"
VERSION=""
DRY_RUN=0
TAG_RE='^v[0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,6}$'

step() { printf '==> %s\n' "$*"; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

while (($# > 0)); do
  case "$1" in
    --version) VERSION="${2:?--version needs a release, like v1.0.0}"; shift ;;
    --repo) SLUG="${2:?--repo needs owner/name}"; shift ;;
    --dry-run) DRY_RUN=1 ;;
    -h | --help) sed -n '2,9p' "${BASH_SOURCE[0]:-install.sh}" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
  shift
done

if [[ ! "$SLUG" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]*/[A-Za-z0-9_][A-Za-z0-9_.-]*$ ]]; then
  die "not a repository: $SLUG (like owner/name)"
fi
if [[ -n "$VERSION" && ! "$VERSION" =~ $TAG_RE ]]; then
  die "not a release: $VERSION (like v1.0.0)"
fi
# Installing into /usr/local/bin needs root; a dry run, or a test's own folder, does not.
if ((!DRY_RUN)) && [[ -z "${WPCORE_BIN_DIR:-}" && ${EUID:-$(id -u)} -ne 0 ]]; then
  die "installing into $BIN_DIR needs root: curl -fsSL https://webtimeless.cloud/wpcore-manager.sh | sudo bash"
fi
for cmd in curl sha256sum; do
  command -v "$cmd" >/dev/null 2>&1 || die "$cmd is needed (apt install $cmd)"
done

# The newest release: GitHub redirects releases/latest to the newest release's tag page.
if [[ -z "$VERSION" ]]; then
  [[ -z "$BASE" ]] || die "--version is needed with WPCORE_DOWNLOAD_BASE"
  latest="$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/$SLUG/releases/latest")" ||
    die "cannot reach github.com/$SLUG"
  VERSION="${latest##*/}"
  [[ "$VERSION" =~ $TAG_RE ]] || die "github.com/$SLUG has no release yet"
fi

BASE="${BASE:-https://github.com/$SLUG/releases/download/$VERSION}"
step "wpcore $VERSION from $SLUG"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

step "Downloading wpcore"
curl -fsSL -o "$tmp/wpcore" "$BASE/wpcore" || die "cannot download $BASE/wpcore"
curl -fsSL -o "$tmp/wpcore.sha256" "$BASE/wpcore.sha256" || die "cannot download $BASE/wpcore.sha256"

step "Checking it against wpcore.sha256"
(cd "$tmp" && sha256sum --check --quiet --strict wpcore.sha256) ||
  die "wpcore does not match its checksum; nothing was installed"
bash -n "$tmp/wpcore" || die "the downloaded wpcore does not parse; nothing was installed"

if ((DRY_RUN)); then
  step "Dry run: wpcore $VERSION checks out; it would go in $BIN_DIR/wpcore"
  exit 0
fi

# Into place in one step: a copy next to the target, then a rename over it.
mkdir -p "$BIN_DIR"
install -m 0755 "$tmp/wpcore" "$BIN_DIR/.wpcore.new"
mv -f "$BIN_DIR/.wpcore.new" "$BIN_DIR/wpcore"
step "Installed $BIN_DIR/wpcore ($VERSION)"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) printf 'note: %s is not in PATH; add it in your shell profile\n' "$BIN_DIR" ;;
esac

# Offer `wpcore init` on a first install. Piped into bash, stdin is this script, so ask the terminal.
if [[ -f /etc/wpcore.conf || -n "${WPCORE_BIN_DIR:-}" ]]; then
  step "Done. Run 'wpcore help' to get started."
elif { : </dev/tty; } 2>/dev/null; then
  read -rp "Run 'wpcore init' now, to write /etc/wpcore.conf and tab completion? [Y/n] " answer </dev/tty
  if [[ "${answer:-Y}" =~ ^[Yy]$ ]]; then
    "$BIN_DIR/wpcore" init
  else
    step "Skipped. Run 'sudo wpcore init' when you are ready."
  fi
else
  step "Next: run 'sudo wpcore init' to write /etc/wpcore.conf and tab completion."
fi
