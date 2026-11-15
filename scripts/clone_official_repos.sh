#!/usr/bin/env bash
# Clone the official PLE repos into vendor/ (git-ignored).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p vendor
[ -d vendor/ple ] || git clone --depth 1 https://github.com/google-research/ple.git vendor/ple
[ -d vendor/submission-template ] || git clone --depth 1 https://github.com/physical-engineerings-last-exam/submission-template.git vendor/submission-template
echo "Cloned into $(pwd)/vendor/"
