/**
 # Teemoji

 A command-line tool similar to the classic `tee` utility, but uses a Core ML model to predict an appropriate emoji to prepend each incoming line of text.

 **Usage**
 ```bash
 cat input.txt | teemoji [options] [FILE...]
 ```

 **Options**
 - `-a`, `--append`: Append to the given FILE(s), do not overwrite.
 - `-h`, `--help`: Display help information.

 This tool reads from standard input, writes to standard output, and can also write to one or more files.
 */

import CoreML
import Foundation

/// The main entry point for the Teemoji command-line tool.
///
/// This `@main` struct orchestrates parsing command-line arguments, opening files in append or write modes,
/// loading the `TeemojiClassifier` model, reading lines from standard input, and writing them (with an emoji) to
/// standard output and each specified file.

@main
struct Teemoji {
    /**
     The main function for the `Teemoji` CLI tool.

     This function processes command-line arguments, manages file I/O, and uses the Core ML model to predict emojis for
     each line read from standard input.

     - Parameters:
        - arguments: Typically includes the executable name and any flags / file paths.
     - Returns: Does not return; the process runs until EOF on standard input.
     */
    static func main() {
        // Parse command-line arguments
        var arguments = CommandLine.arguments
        // The first argument is the executable name, so remove it.
        arguments.removeFirst()

        // Check if the user asked for help
        if arguments.contains("-h") || arguments.contains("--help") {
            printUsage()
            exit(EXIT_SUCCESS)
        }

        // Check for append flag (-a / --append) and strip it out
        let append = arguments.contains("-a") || arguments.contains("--append")
        arguments.removeAll(where: { $0 == "-a" || $0 == "--append" })

        // The remaining arguments are taken to be filenames (like `tee file1 file2 ...`)
        let fileURLs = arguments.map { URL(fileURLWithPath: $0) }

        // Open file handles for writing or appending
        var fileHandles: [FileHandle] = []
        for url in fileURLs {
            do {
                // If appending, open or create the file; otherwise create/truncate it.
                if append {
                    // Create the file if it doesn’t exist; otherwise open for appending.
                    if !FileManager.default.fileExists(atPath: url.path) {
                        FileManager.default.createFile(atPath: url.path, contents: nil)
                    }
                    let handle = try FileHandle(forWritingTo: url)
                    // Move the write pointer to the end if appending
                    try handle.seekToEnd()
                    fileHandles.append(handle)
                } else {
                    // Overwrite by creating a new file (truncating existing contents)
                    FileManager.default.createFile(atPath: url.path, contents: nil)
                    let handle = try FileHandle(forWritingTo: url)
                    fileHandles.append(handle)
                }
            } catch {
                fputs("teemoji: cannot open \(url.path): \(error)\n", stderr)
            }
        }

        // Make sure handles are closed at the end
        defer {
            for handle in fileHandles {
                try? handle.close()
            }
        }

        guard
            let modelURL = Bundle.module.url(
                forResource: "TeemojiClassifier", withExtension: "mlmodelc")
        else {
            fputs("teemoji: failed to load CoreML model.\n", stderr)
            exit(EXIT_FAILURE)
        }

        guard let rawModel = try? MLModel(contentsOf: modelURL) else {
            fputs("teemoji: failed to load CoreML model.\n", stderr)
            exit(EXIT_FAILURE)
        }

        let model = TeemojiClassifier(model: rawModel)

        // Read lines from stdin, predict an emoji, write to stdout & files
        while let line = readLine() {
            // Attempt inference on the line
            let predictionLabel: String
            do {
                let prediction = try model.prediction(text: line)
                predictionLabel = prediction.label
            } catch {
                // If model prediction fails for any reason, fall back to no emoji
                predictionLabel = "❓"
            }

            let outputLine = "\(predictionLabel) \(line)\n"

            // Always write to stdout
            fputs(outputLine, stdout)

            // Also write to each open file
            if let data = outputLine.data(using: .utf8) {
                for handle in fileHandles {
                    do {
                        try handle.write(contentsOf: data)
                    } catch {
                        fputs("teemoji: error writing to file: \(error)\n", stderr)
                    }
                }
            }
        }
    }
}

/// Prints usage information to stdout.
///
/// Call this function when `-h` or `--help` flags are detected, or whenever you want
/// to remind users how to operate the tool.
func printUsage() {
    let usage = """
        Usage: teemoji [options] [FILE...]

        Like the standard 'tee' command, teemoji reads from standard input and writes to standard output
        and the specified FILEs, but prepends an emoji to each line inferred by a Core ML model.

        Options:
          -a, --append   Append to the given FILE(s), do not overwrite.
          -h, --help     Display this help message.

        Examples:
          cat input.txt | teemoji output.txt
          cat input.txt | teemoji -a output.txt another.log
        """
    print(usage)
}
