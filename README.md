# teemoji

**teemoji** is a command-line tool inspired by the classic [`tee`](https://en.wikipedia.org/wiki/Tee_(command)) utility. Unlike `tee`, `teemoji` leverages a Core ML model to predict and prepend an appropriate emoji to each incoming line of text, adding a touch of fun and context to your command-line workflows.

## Features

- **Emoji Prediction:** Uses a Core ML model to intelligently select emojis based on the input text.
- **Standard I/O Support:** Reads from standard input and writes to both standard output and specified files.
- **File Handling Options:** Choose to append to existing files or overwrite them.
- **Easy Integration:** Seamlessly fits into your existing shell pipelines.

## Installation

You can install `teemoji` via [Homebrew](https://brew.sh/):

```bash
brew install willswire/teemoji
```

## Usage

`teemoji` works similarly to the standard `tee` command but with the added functionality of prepending emojis to each line.

### Basic Usage

Pipe the output of a command into `teemoji` to see emojis added to each line and simultaneously write to a file.

```bash
cat input.txt | teemoji output.txt
```

### Append to Files

Use the `-a` or `--append` flag to append the output to existing files instead of overwriting them.

```bash
cat input.txt | teemoji -a output.txt another.log
```

### Display Help

Get help information about `teemoji`'s options and usage.

```bash
teemoji --help
```

### Options

- `-a`, `--append`: Append to the given FILE(s), do not overwrite.
- `-h`, `--help`: Display help information.

## Example

Suppose you have a file named `messages.txt` and you want to log its contents with emojis:

```bash
cat messages.txt | teemoji --append log.txt
```

This command will read each line from `messages.txt`, prepend an emoji based on the content, display it on the terminal, and append it to `log.txt`.

## Development

If you're interested in contributing or building `teemoji` from source:

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/willswire/teemoji.git
   cd teemoji
   ```

2. **Build the Project:**

   Ensure you have Swift 6.0 and Xcode 15 installed.

   ```bash
   just build
   ```

## License

Distributed under the MIT License. See [`LICENSE`](https://github.com/willswire/teemoji/blob/main/LICENSE) for more information.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or feature requests.

## Acknowledgements

- Built with [Swift](https://swift.org/) and [Core ML](https://developer.apple.com/documentation/coreml).
- Inspired by the classic `tee` utility.
