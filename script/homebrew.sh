#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -ne 2 ]; then
  echo "usage: $0 <version> <file>" >&2
  exit 1
fi

version="$1"
file="$2"

url="https://github.com/nicholasdower/quote/releases/download/v$version/$file"
sha=`shasum -a 256 "$file" | cut -d' ' -f1`
cat << EOF > Formula/quote.rb
class Quote < Formula
  desc "Quote lines"
  homepage "https://github.com/nicholasdower/quote"
  url "$url"
  sha256 "$sha"
  license "MIT"

  def install
    bin.install "bin/quote"
    man1.install "man/quote.1"
  end

  test do
    assert_match "quote", shell_output("#{bin}/quote --version")
  end
end
EOF
