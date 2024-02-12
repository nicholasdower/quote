#!/usr/bin/env bash

if [[ -z "$RUNNER_TEMP" ]]; then
  dir="/tmp/quote"
else
  dir="$RUNNER_TEMP/quote"
fi

rm -rf "$dir"
mkdir -p "$dir"
cp ./target/release/quote "$dir"
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

printf 'foo\n' > one
./quote one 2>&1 > actual
printf '"foo"\n' > expected
test 'file: single line with newline'

printf 'foo' > one
./quote one 2>&1 > actual
printf '"foo"' > expected
test 'file: single line without newline'

printf 'foo\nbar\n' > one
./quote one 2>&1 > actual
printf '"foo"\n"bar"\n' > expected
test 'file: multiline with newline'

printf 'foo\nbar' > one
./quote one 2>&1 > actual
printf '"foo"\n"bar"' > expected
test 'file: multiline without newline'

printf 'foo\n' > one
printf 'bar\n' > two
./quote one two 2>&1 > actual
printf '"foo"\n"bar"\n' > expected
test 'files: with newline'

printf 'foo' > one
printf 'bar' > two
./quote one two 2>&1 > actual
printf '"foo"\n"bar"' > expected
test 'files: without newline'

printf '' > one
printf '' > two
printf '' > tre
./quote one two tre 2>&1 > actual
printf '""\n""\n""' > expected
test 'files: all empty'

printf 'foo' > one
printf '' > two
printf 'bar' > tre
./quote one two tre 2>&1 > actual
printf '"foo"\n""\n"bar"' > expected
test 'files: some empty'

printf 'foo\nbar\n' | ./quote -q '' 2>&1 > actual
printf 'foo\nbar\n' > expected
test 'quote character: '

printf 'foo\nbar\n' | ./quote -q "'" 2>&1 > actual
printf "'foo'\n'bar'\n" > expected
test "quote character: '"

printf 'foo\nbar\n' | ./quote -q 'FOO' 2>&1 > actual
printf 'FOOfooFOO\nFOObarFOO\n' > expected
test 'quote character: FOO'

printf 'foo\nbar\n' | ./quote -q '\tF' 2>&1 > actual
printf '\tFfoo\tF\n\tFbar\tF\n' > expected
test 'quote character: \tF'

printf 'foo\nbar\n' | ./quote -s 'S' 2>&1 > actual
printf 'Sfoo\nSbar\n' > expected
test 'start character: S'

printf 'foo\nbar\n' | ./quote -s '\tS' 2>&1 > actual
printf '\tSfoo\n\tSbar\n' > expected
test 'start character: \tS'

printf 'foo\nbar\n' | ./quote -e 'E' 2>&1 > actual
printf 'fooE\nbarE\n' > expected
test 'end character: E'

printf 'foo\nbar\n' | ./quote -e '\tE' 2>&1 > actual
printf 'foo\tE\nbar\tE\n' > expected
test 'end character: \tE'

printf '' | ./quote -q -s '' 2>&1 | head -n 1 > actual
printf "error: one of the values isn't valid for an argument\n" > expected
test 'error: -q -s'

printf '' | ./quote -q -e '' 2>&1 | head -n 1 > actual
printf "error: one of the values isn't valid for an argument\n" > expected
test 'error: -q -e'
