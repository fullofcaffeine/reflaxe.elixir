#!/usr/bin/env bash
set -euo pipefail
# Wrapper to ensure rebar3 sees correct library roots when Mix uses a per-run MIX_BUILD_ROOT.
# This helps include_lib("cowlib/include/...") resolve under rebar bare compile with custom paths.

# Determine lib root from the active Mix environment and build root
MIX_ENV_NAME=${MIX_ENV:-dev}
if [[ -n "${MIX_BUILD_ROOT:-}" ]]; then
  export ERL_LIBS="${ERL_LIBS:-${MIX_BUILD_ROOT}/${MIX_ENV_NAME}/lib}"
fi

# Locate the real rebar3 binary (Mix embeds it under ~/.mix/elixir/*/rebar3)
REAL_REBAR3=""
if command -v rebar3 >/dev/null 2>&1; then
  REAL_REBAR3="$(command -v rebar3)"
else
  REAL_REBAR3="$(ls -1t "$HOME/.mix/elixir"/*/rebar3 2>/dev/null | head -n1 || true)"
fi
if [[ -z "$REAL_REBAR3" ]]; then
  echo "rebar3 not found" >&2
  exit 127
fi

exec "$REAL_REBAR3" "$@"
