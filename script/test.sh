#!/usr/bin/env bash

if [[ -z "$RUNNER_TEMP" ]]; then
  dir="/tmp/quote"
else
  dir="$RUNNER_TEMP/quote"
fi

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

rm -rf "$dir"
mkdir -p "$dir"
cp "$binary" "$dir"
cd "$dir"

function test() {
  name="$1"
  if diff expected actual > /dev/null; then
    printf "\033[0;32m"
    echo "test passed: $name"
    printf "\033[0m"
  else
    printf "\033[0;31m"
    echo "test failed: $name"
    printf "\033[0m"
    diff expected actual
    exit 1
  fi
}

printf "foo\n" | ./quote 2>&1 > actual
printf '"foo"\n' > expected
test "stdin: single line with newline"

printf 'foo' | ./quote 2>&1 > actual
printf '"foo"' > expected
test 'stdin: single line without newline'

printf 'foo\nbar\n' | ./quote 2>&1 > actual
printf '"foo"\n"bar"\n' > expected
test 'stdin: muliline with newline'

printf 'foo\nbar' | ./quote 2>&1 > actual
printf '"foo"\n"bar"' > expected
test 'stdin: muliline without newline'

printf 'foo\n\nbar\n' | ./quote 2>&1 > actual
printf '"foo"\n""\n"bar"\n' > expected
test 'stdin: blank lines'

printf 'foo\n\n' | ./quote 2>&1 > actual
printf '"foo"\n""\n' > expected
test 'stdin: trailing blank lines'

printf 'foo\nbar\n' | ./quote '' 2>&1 > actual
printf 'foo\nbar\n' > expected
test 'quote character: '

printf 'foo\nbar\n' | ./quote "'" 2>&1 > actual
printf "'foo'\n'bar'\n" > expected
test "quote character: '"

printf 'foo\nbar\n' | ./quote 'FOO' 2>&1 > actual
printf 'FOOfooFOO\nFOObarFOO\n' > expected
test 'quote character: FOO'

printf 'foo\nbar\n' | ./quote '\tF' 2>&1 > actual
printf '\tFfoo\tF\n\tFbar\tF\n' > expected
test 'quote character: \tF'

printf 'foo\nbar\n' | ./quote 'S' '' 2>&1 > actual
printf 'Sfoo\nSbar\n' > expected
test 'start character: S'

printf 'foo\nbar\n' | ./quote '\tS' '' 2>&1 > actual
printf '\tSfoo\n\tSbar\n' > expected
test 'start character: \tS'

printf 'foo\nbar\n' | ./quote '' 'E' 2>&1 > actual
printf 'fooE\nbarE\n' > expected
test 'end character: E'

printf 'foo\nbar\n' | ./quote '' '\tE' 2>&1 > actual
printf 'foo\tE\nbar\tE\n' > expected
test 'end character: \tE'
