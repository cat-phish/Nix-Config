#!/usr/bin/env bash
set -euo pipefail

# Small helper to apply the `jordan@fedora-live` homeConfiguration from this flake.
# Place this script under hosts/fedora-live/ and run it from the Fedora machine after cloning the repo.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLAKE_REF="$REPO_ROOT#jordan@fedora-live"

echo "Using flake: $FLAKE_REF"

if ! command -v nix >/dev/null 2>&1; then
  cat <<'EOF'
Nix is not installed. Install it first:
  sh <(curl -L https://nixos.org/nix/install) --no-daemon
After installation, enable flakes (single-user):
  mkdir -p ~/.config/nix
  echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
Then rerun this script.
EOF
  exit 1
fi

if command -v home-manager >/dev/null 2>&1; then
  echo "Found home-manager in PATH — running switch."
  home-manager switch --flake "$FLAKE_REF"
  exit $?
fi

# If home-manager isn't installed, try to run it via nix. This uses the community flake
# which will run the home-manager binary and invoke the switch for our flake.

echo "home-manager not found — attempting to run via 'nix run' (this requires flakes enabled)."

nix run github:nix-community/home-manager -c home-manager switch --flake "$FLAKE_REF"

exit $?
