#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
install_nix="$repo_root/pkgs/mplab-install.nix"

xc32_line=$(grep 'XC32_VERSIONS=' "$install_nix")
mapfile -t xc32_versions < <(printf '%s\n' "$xc32_line" | grep -oE '"[0-9]+\.[0-9]+"' | tr -d '"')

expected_xc32_versions=(
  "5.10"
  "5.00"
  "4.60"
  "4.50"
  "4.45"
  "4.40"
  "4.35"
  "4.30"
  "4.21"
  "4.20"
)

if [ "${xc32_versions[*]}" != "${expected_xc32_versions[*]}" ]; then
  printf 'XC32_VERSIONS mismatch\n' >&2
  printf 'expected: %s\n' "${expected_xc32_versions[*]}" >&2
  printf 'actual:   %s\n' "${xc32_versions[*]}" >&2
  exit 1
fi
