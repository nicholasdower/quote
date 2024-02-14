#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <version>" >&2
  exit 1
fi

version="$1"

x86_64_apple_darwin_file="quote-$version-x86_64-apple-darwin.tar.gz"
aarch64_apple_darwin_file="quote-$version-aarch64-apple-darwin.tar.gz"

if [ ! -f "$x86_64_apple_darwin_file" ]; then
  echo "error: $x86_64_apple_darwin_file not found" >&2
  exit 1
fi

if [ ! -f "$aarch64_apple_darwin_file" ]; then
  echo "error: $aarch64_apple_darwin_file not found" >&2
  exit 1
fi

x86_64_apple_darwin_url="https://github.com/nicholasdower/quote/releases/download/v$version/$x86_64_apple_darwin_file"
x86_64_apple_darwin_sha=`shasum -a 256 "$x86_64_apple_darwin_file" | cut -d' ' -f1`

aarch64_apple_darwin_url="https://github.com/nicholasdower/quote/releases/download/v$version/$aarch64_apple_darwin_file"
aarch64_apple_darwin_sha=`shasum -a 256 "$aarch64_apple_darwin_file" | cut -d' ' -f1`

cat << EOF > Formula/quote.rb
class Quote < Formula
  desc "Quote lines"
  homepage "https://github.com/nicholasdower/quote"
  license "MIT"
  version "$version"
  if Hardware::CPU.arm?
    url "$aarch64_apple_darwin_url"
    sha256 "$aarch64_apple_darwin_sha"
  elsif Hardware::CPU.intel?
    url "$x86_64_apple_darwin_url"
    sha256 "$x86_64_apple_darwin_sha"
  end

  def install
    bin.install "bin/quote"
    man1.install "man/quote.1"
  end

  test do
    assert_match "quote", shell_output("#{bin}/quote --version")
  end
end
EOF
