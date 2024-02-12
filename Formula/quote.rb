class Quote < Formula
  desc "Quote lines"
  homepage "https://github.com/nicholasdower/quote"
  url "https://github.com/nicholasdower/quote/releases/download/v1.0.0/release.tar.gz"
  sha256 "TBD"
  license "MIT"

  def install
    bin.install "bin/quote"
    man1.install "man/quote.1"
  end

  test do
    assert_match "quote", shell_output("#{bin}/quote --version")
  end
end
