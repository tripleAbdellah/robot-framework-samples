#!/usr/bin/env bash
# Loads .env into your CURRENT shell session, once, so `robot` picks it up via
# %{ENV_VAR} for as many commands as you run afterward — same idea as
# activating a Python venv once and using python/pip freely after.
#
# IMPORTANT: source this script, don't execute it — it needs to modify your
# CURRENT shell's environment, which only works if it runs *in* this shell,
# not a child process that exits immediately after:
#
#   source init-env.sh
#   . init-env.sh
#
# Running it directly (./init-env.sh) leaves your terminal session unchanged —
# no error, just silently useless, which is why this checks for that below.

if (return 0 2>/dev/null); then
    :  # sourced correctly, continue
else
    echo "This script must be sourced, not executed directly. Run:" >&2
    echo "  source ${BASH_SOURCE[0]:-init-env.sh}" >&2
    exit 1
fi

if [[ ! -f .env ]]; then
    echo "No .env file found. Copy .env.example to .env and fill in real values first:" >&2
    echo "  cp .env.example .env" >&2
    return 1
fi

set -a
source .env
set +a

echo "Loaded from .env:"
grep -E '^[A-Za-z_][A-Za-z0-9_]*=' .env | cut -d= -f1 | sed 's/^/  /'
