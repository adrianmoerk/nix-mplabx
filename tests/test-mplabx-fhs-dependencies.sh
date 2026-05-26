#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fhs_nix="$repo_root/pkgs/mplabx-fhs.nix"

required_runtime_packages=(
  "git"
  "cacert"
  "curl"
  "unzip"
  "zip"
  "gnutar"
  "gzip"
  "xdg-utils"
  "procps"
  "which"
)

for package in "${required_runtime_packages[@]}"; do
  if ! grep -Eq "^[[:space:]]+$package([[:space:]]|$)" "$fhs_nix"; then
    printf 'Missing FHS runtime package: %s\n' "$package" >&2
    exit 1
  fi
done
