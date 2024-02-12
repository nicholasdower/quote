use clap::Parser;
use std::{fs::File, io::{self, BufRead, Write}};

const VERSION: &str = env!("CARGO_PKG_VERSION");

const HELP: &str = "\
usage: quote ([-q <quote>] | [-s <start>] [-e <end>]) [file ...]

Quote lines

Options

    -q, --quote      The quote character.
    -s, --start      The staring quote character.
    -e, --end        The ending quote character.
    -h, --help       Print help.
    -v, --version    Print version.

Installation

    Install:

        brew install nicholasdower/tap/quote

    Uninstall:

        brew uninstall quote
";

#[derive(Parser)]
#[command(disable_help_flag = true)]
struct Cli {
    #[arg(short, long)]
    help: bool,

    #[arg(short, long)]
    version: bool,

    #[arg(short, long)]
    quote: Option<String>,
    
    #[arg(short = 's', long)]
    start: Option<String>,

    #[arg(short, long)]
    end: Option<String>,

    #[arg(name = "file")]
    files: Vec<String>,
}

fn main() {
    match run() {
        Ok(_) => std::process::exit(0),
        Err(e) => {
            eprintln!("error: {e}");
            std::process::exit(1);
        },
    }
}

fn run() -> Result<(), String> {
    let args = Cli::try_parse().map_err(|e| format!("{}\n{HELP}", e.kind()))?;

    if args.help {
        println!("{HELP}");
        Ok(())
    } else if args.version {
        println!("quote {VERSION}");
        Ok(())
    } else if args.quote.is_some() {
        if args.start.is_some() || args.end.is_some() {
            return Err("you may not specify --start or --end with --quote".to_string());
        }
        let quote = convert_escape_sequences(&args.quote.unwrap());
        stream_all(args.files, quote.as_bytes(), quote.as_bytes())
    } else if args.start.is_some() || args.end.is_some() {
        let start = convert_escape_sequences(&args.start.unwrap_or("".to_string()));
        let end = convert_escape_sequences(&args.end.unwrap_or("".to_string()));
        stream_all(args.files, start.as_bytes(), end.as_bytes())
    } else {
        stream_all(args.files, "\"".as_bytes(), "\"".as_bytes())
    }
}

fn stream_all(files: Vec<String>, start: &[u8], end: &[u8]) -> Result<(), String> {
    if !files.is_empty() {
        let newline_bytes = "\n".as_bytes();
        let mut newline = false;

        files.iter().enumerate().try_for_each(|(i, file_path)| {
            match File::open(file_path) {
                Ok(file) => {
                    if i > 0 && !newline {
                        io::stdout().write_all(newline_bytes).map_err(|e| format!("{e}"))?;
                    }
                    newline = stream_one(io::BufReader::new(file), start, end)?;
                    Ok(())
                },
                Err(e) => Err(format!("{e}")),
            }
        })?;
    } else if atty::is(atty::Stream::Stdin) {
        return Err("nothing to quote".to_string());
    } else {
        stream_one(io::stdin().lock(), start, end)?;
    }
    Ok(())
}

fn stream_one<R: BufRead>(mut handle: R, start: &[u8], end: &[u8]) -> Result<bool, String> {
    let mut stdout = io::stdout();
    let mut quoted = false;
    let mut newline = false;
    let mut any = false;

    loop {
        let buffer = match handle.fill_buf() {
            Ok(buf) => buf,
            Err(e) => return Err(format!("{e}"))
        };

        if buffer.is_empty() {
            break;
        }

        let buffer_len = buffer.len();
        for &byte in buffer {
            if byte == b'\n' {
                if quoted {
                    stdout.write_all(end).map_err(|e| format!("{e}"))?;
                } else {
                    stdout.write_all(start).map_err(|e| format!("{e}"))?;
                    stdout.write_all(end).map_err(|e| format!("{e}"))?;
                }
                newline = true;
                quoted = false;
            } else {
                if !quoted {
                    stdout.write_all(start).map_err(|e| format!("{e}"))?;
                    quoted = true;
                }
                newline = false;
            }
            any = true;
            stdout.write_all(&[byte]).map_err(|e| format!("{e}"))?;
        }

        handle.consume(buffer_len);
    }

    if quoted {
        stdout.write_all(end).map_err(|e| format!("{e}"))?;
    }

    if !any {
        stdout.write_all(start).map_err(|e| format!("{e}"))?;
        stdout.write_all(end).map_err(|e| format!("{e}"))?;
    }

    Ok(newline)
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