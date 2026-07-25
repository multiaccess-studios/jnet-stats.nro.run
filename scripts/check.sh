#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root

cd "${repository_root}"
bun install --frozen-lockfile
bun run lint
bun run build
