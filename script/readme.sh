#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -gt 1 ]; then
  echo "usage: $0 [<bin-path>]" >&2
  exit 1
fi

if [ $# -eq 1 ]; then
  binary="$1/quote"
else
  binary="./target/debug/quote"
fi

if [ ! -f "$binary" ]; then
  echo "error: $binary does not exist" >&2
  exit 1
fi

cat << EOF > README.md
# quote

## Install

\`\`\`shell
brew install nicholasdower/tap/quote
\`\`\`

## Uninstall

\`\`\`shell
brew uninstall quote
\`\`\`

## Help

\`\`\`
$($binary -h)
\`\`\`
EOF
