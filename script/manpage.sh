#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ $# -ne 2 ]; then
  echo "usage: $0 <version> <date>" >&2
  exit 1
fi

version="$1"
date="$2"

rm -rf man
mkdir man
cat << EOF > man/quote.1
.TH QUOTE 1 $date $version ""
.SH NAME
\fBquote\fR \- Quote lines
.SH SYNOPSIS
.nf
\fBquote\fR
\fBquote\fR <quote>
\fBquote\fR <start-quote> <end-quote>
.fi
.SH DESCRIPTION
Quote lines, optionally using the specified quote character(s).
.SH OPTIONS
.TP
\fB\-h, \-\-help\fR
Print help\.
.TP
\fB\-v\, \-\-version\fR
Print the version\.
EOF
