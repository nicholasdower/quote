use clap::Parser;
use std::io::{self, BufRead, Write};

const VERSION: &str = env!("CARGO_PKG_VERSION");

const HELP: &str = "\
usage:
    quote
    quote <quote>
    quote <start-quote> <end-quote>

Description

    Quote lines, optionally using the specified quote character(s).

Options

    -h, --help       Print help.
    -v, --version    Print version.\
";

#[derive(Parser)]
#[command(disable_help_flag = true)]
struct Cli {
    #[arg(short, long)]
    help: bool,

    #[arg(short, long)]
    version: bool,

    #[arg()]
    quote_characters: Vec<String>,
}

fn main() {
    match run() {
        Ok(_) => std::process::exit(0),
        Err(e) => {
            eprintln!("error: {e}");
            std::process::exit(1);
        }
    }
}

fn run() -> Result<(), String> {
    let args = Cli::try_parse().map_err(|e| format!("{}\n{HELP}", e.kind()))?;

    if args.help {
        println!("{HELP}");
        return Ok(());
    }

    if args.version {
        println!("quote {VERSION}");
        return Ok(());
    }

    if atty::is(atty::Stream::Stdin) {
        return Err("nothing to quote".to_string());
    }

    if args.quote_characters.is_empty() {
        let quote_character = "\"".to_string();
        stream(&quote_character, &quote_character).map_err(|e| e.to_string())
    } else if args.quote_characters.len() == 1 {
        let quote_character = convert_escape_sequences(&args.quote_characters[0]);
        stream(&quote_character, &quote_character).map_err(|e| e.to_string())
    } else if args.quote_characters.len() == 2 {
        let start = convert_escape_sequences(&args.quote_characters[0]);
        let end = convert_escape_sequences(&args.quote_characters[1]);
        stream(&start, &end).map_err(|e| e.to_string())
    } else {
        Err("unexpected arguments".to_string())
    }
}

fn stream(start: &String, end: &String) -> io::Result<()> {
    let start = start.as_bytes();
    let end = end.as_bytes();

    let mut stdin = io::stdin().lock();
    let mut stdout = io::stdout();
    let mut quoted = false;
    let mut wrote_something = false;

    loop {
        let buffer = stdin.fill_buf()?;

        if buffer.is_empty() {
            break;
        }

        let buffer_len = buffer.len();
        for &byte in buffer {
            if byte == b'\n' {
                if quoted {
                    stdout.write_all(end)?;
                } else {
                    stdout.write_all(start)?;
                    stdout.write_all(end)?;
                }
                quoted = false;
            } else if !quoted {
                stdout.write_all(start)?;
                quoted = true;
            }
            wrote_something = true;
            stdout.write_all(&[byte])?;
        }

        stdin.consume(buffer_len);
    }

    if quoted {
        stdout.write_all(end)?;
    }

    if !wrote_something {
        stdout.write_all(start)?;
        stdout.write_all(end)?;
    }

    Ok(())
}

fn convert_escape_sequences(input: &str) -> String {
    let mut result = String::with_capacity(input.len());

    let mut chars = input.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '\\' {
            match chars.peek() {
                Some(&'n') => {
                    result.push('\n');
                    chars.next();
                }
                Some(&'t') => {
                    result.push('\t');
                    chars.next();
                }
                Some(&'\\') => {
                    result.push('\\');
                    chars.next();
                }
                Some(&d) => {
                    result.push(d);
                    chars.next();
                }
                _ => result.push(c),
            }
        } else {
            result.push(c);
        }
    }

    result
}
