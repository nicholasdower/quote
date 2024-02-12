#!/usr/bin/env bash

set -e
set -u
set -o pipefail

cat << EOF > README.md
# quote

\`\`\`
$(./target/release/quote -h)
\`\`\`
EOF
