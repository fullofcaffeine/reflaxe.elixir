#!/usr/bin/env bash
set -euo pipefail

# Keep the reviewed release identity in this repository. Downloading a checksum
# beside the archive at runtime would let the same compromised source replace
# both files. Update these values together after reviewing the upstream release.
readonly GITLEAKS_VERSION="8.21.2"
readonly GITLEAKS_ASSET="gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"
readonly GITLEAKS_SHA256="5bc41815076e6ed6ef8fbecc9d9b75bcae31f39029ceb55da08086315316e3ba"
readonly GITLEAKS_DOWNLOAD_URL="https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/${GITLEAKS_ASSET}"

usage() {
	cat <<'EOF'
Usage: scripts/ci/install-gitleaks.sh --install-dir DIR [--archive FILE]

Downloads the repository-pinned Linux x64 Gitleaks release, verifies its
SHA-256 before extraction, verifies the binary version, and installs it in DIR.
--archive supplies already-downloaded bytes for offline verification or tests.
EOF
}

sha256_file() {
	local file="$1"
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$file" | awk '{print $1}'
	elif command -v shasum >/dev/null 2>&1; then
		shasum -a 256 "$file" | awk '{print $1}'
	else
		echo "[gitleaks-install] ERROR: sha256sum or shasum is required" >&2
		return 1
	fi
}

is_linux_x64() {
	[[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]]
}

install_dir=""
provided_archive=""
while [[ $# -gt 0 ]]; do
	case "$1" in
		--install-dir)
			[[ $# -ge 2 ]] || {
				echo "[gitleaks-install] ERROR: --install-dir requires a value" >&2
				exit 2
			}
			install_dir="$2"
			shift 2
			;;
		--archive)
			[[ $# -ge 2 ]] || {
				echo "[gitleaks-install] ERROR: --archive requires a value" >&2
				exit 2
			}
			provided_archive="$2"
			shift 2
			;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			echo "[gitleaks-install] ERROR: unknown argument: $1" >&2
			usage >&2
			exit 2
			;;
	esac
done

if [[ -z "$install_dir" ]]; then
	echo "[gitleaks-install] ERROR: --install-dir is required" >&2
	exit 2
fi

umask 077
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe-elixir-gitleaks.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

archive="$provided_archive"
if [[ -z "$archive" ]]; then
	if ! is_linux_x64; then
		echo "[gitleaks-install] ERROR: the pinned CI binary supports Linux x64 only" >&2
		exit 2
	fi
	archive="$tmp_dir/$GITLEAKS_ASSET"
	curl --proto '=https' --tlsv1.2 -fsSL \
		--connect-timeout 15 --max-time 180 \
		--retry 5 --retry-all-errors --retry-delay 2 \
		-o "$archive" "$GITLEAKS_DOWNLOAD_URL"
elif [[ ! -f "$archive" ]]; then
	echo "[gitleaks-install] ERROR: archive does not exist: $archive" >&2
	exit 2
fi

actual_sha256="$(sha256_file "$archive")"
if [[ "$actual_sha256" != "$GITLEAKS_SHA256" ]]; then
	echo "[gitleaks-install] ERROR: checksum mismatch for $GITLEAKS_ASSET" >&2
	echo "[gitleaks-install] expected: $GITLEAKS_SHA256" >&2
	echo "[gitleaks-install] actual:   $actual_sha256" >&2
	exit 1
fi

if ! is_linux_x64; then
	echo "[gitleaks-install] ERROR: verified the archive, but the pinned CI binary supports Linux x64 only" >&2
	exit 2
fi

# Extraction and execution happen only after the reviewed digest matches.
tar -xzf "$archive" -C "$tmp_dir" gitleaks
chmod 0755 "$tmp_dir/gitleaks"
reported_version="$("$tmp_dir/gitleaks" version | tr -d '\r\n')"
if [[ "$reported_version" != "$GITLEAKS_VERSION" ]]; then
	echo "[gitleaks-install] ERROR: expected Gitleaks $GITLEAKS_VERSION, binary reported $reported_version" >&2
	exit 1
fi

mkdir -p "$install_dir"
install -m 0755 "$tmp_dir/gitleaks" "$install_dir/gitleaks"
echo "[gitleaks-install] Verified Gitleaks $GITLEAKS_VERSION ($GITLEAKS_SHA256)"
