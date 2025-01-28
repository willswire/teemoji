import CoreML
import Foundation

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

/// The main entry point for the Teemoji command-line tool.
///
/// This `@main` struct orchestrates parsing command-line arguments, opening files in append or write modes,
/// loading the `TeemojiClassifier` model, reading lines from standard input, and writing them (with an emoji) to
/// standard output and each specified file.
@main
struct Teemoji {
    static func main() {
        // Keep track of exit status, default success.
        var exitStatus: Int32 = 0
        // Parse command-line arguments.
        var arguments = CommandLine.arguments
        arguments.removeFirst()  // remove executable name

        // We support -a and -i, plus -h/--help.
        let appendFlagIndex = arguments.firstIndex(where: { $0 == "-a" || $0 == "--append" })
        let ignoreSigIntIndex = arguments.firstIndex(where: { $0 == "-i" })
        let helpFlagIndex = arguments.firstIndex(where: { $0 == "-h" || $0 == "--help" })

        let append = (appendFlagIndex != nil)
        if appendFlagIndex != nil {
            arguments.remove(at: appendFlagIndex!)
        }

        // If -i is present, ignore SIGINT.
        if ignoreSigIntIndex != nil {
            signal(SIGINT, SIG_IGN)
            arguments.remove(at: ignoreSigIntIndex!)
        }

        // If -h or --help is present, print usage and exit.
        if helpFlagIndex != nil {
            printUsage()
            exit(EXIT_SUCCESS)
        }

        // Remaining arguments are treated as file paths.
        let fileURLs = arguments.map { URL(fileURLWithPath: $0) }

        // Open file handles.
        var fileHandles: [(URL, FileHandle)] = []
        for url in fileURLs {
            do {
                if append {
                    // Create file if it doesn’t exist, otherwise open for append.
                    if !FileManager.default.fileExists(atPath: url.path) {
                        FileManager.default.createFile(atPath: url.path, contents: nil)
                    }
                    let handle = try FileHandle(forWritingTo: url)
                    try handle.seekToEnd()
                    fileHandles.append((url, handle))
                } else {
                    // Overwrite by creating a new file.
                    FileManager.default.createFile(atPath: url.path, contents: nil)
                    let handle = try FileHandle(forWritingTo: url)
                    fileHandles.append((url, handle))
                }
            } catch {
                fputs("teemoji: cannot open \(url.path): \(error)\n", stderr)
                exitStatus = 1
            }
        }

        // Ensure handles get closed.
        defer {
            for (_, handle) in fileHandles {
                try? handle.close()
            }
        }

        // Load the ML model.
        guard
            let modelURL = Bundle.module.url(
                forResource: "TeemojiClassifier", withExtension: "mlmodelc"),
            let rawModel = try? MLModel(contentsOf: modelURL)
        else {
            fputs("teemoji: failed to load CoreML model.\n", stderr)
            exit(EXIT_FAILURE)
        }
        let model = TeemojiClassifier(model: rawModel)

        // Read from stdin line by line, predict emoji, then write to stdout & all open files.
        while let line = readLine() {
            // Attempt model inference.
            let predictionLabel: String
            do {
                let prediction = try model.prediction(text: line)
                predictionLabel = prediction.label
            } catch {
                // If model fails, use a fallback.
                predictionLabel = "❓"
            }

            // Prepare output line.
            let outputLine = "\(predictionLabel) \(line)\n"
            // Always write to stdout.
            if fputs(outputLine, stdout) < 0 {
                // If an error occurs while writing to stdout, set exit code.
                exitStatus = 1
            }

            // Also attempt to write to each file.
            if let data = outputLine.data(using: .utf8) {
                for (url, handle) in fileHandles {
                    var offset = 0
                    let length = data.count
                    // Attempt partial-write logic to ensure all data is written.
                    while offset < length {
                        do {
                            // We slice the data from the offset onward.
                            let sliceSize = try handle.writeCompat(
                                data: data, offset: offset, length: length - offset)
                            if sliceSize <= 0 {
                                // Zero or negative means we couldn't write.
                                throw NSError(domain: "WriteError", code: 1, userInfo: nil)
                            }
                            offset += sliceSize
                        } catch {
                            fputs("teemoji: error writing to \(url.path): \(error)\n", stderr)
                            exitStatus = 1
                            break
                        }
                    }
                }
            }
        }

        // Since readLine() returns nil on EOF or error, we can’t distinguish. Just exit.
        // In BFS tee, if read < 0, it calls err(1, "read"). But we can’t detect that.
        // We'll trust readLine only ended due to EOF.

        exit(exitStatus)
    }

    /// Prints usage, matching FreeBSD tee’s style.
    static func printUsage() {
        let usage = """
            usage: teemoji [-ai] [file ...]

            Reads from standard input, writes to standard output and specified files, prepending an emoji
            inferred by a Core ML model to each line. Options:
              -a	Append to the given file(s), do not overwrite
              -i	Ignore SIGINT
              -h	Display help (non-standard extension)
            """
        print(usage)
    }
}

// Extend FileHandle to do partial writes similar to POSIX.
extension FileHandle {
    /// Write a segment of `data` starting from `offset`, returning how many bytes were written.
    fileprivate func writeCompat(data: Data, offset: Int, length: Int) throws -> Int {
        // Slicing the data.
        let subdata = data.subdata(in: offset..<(offset + length))
        // On Apple platforms, `write` should typically write all data, but we mimic partial writes.
        // We'll try writing all subdata at once. If it succeeds, it’s done.
        // If it fails, we throw.
        // This is a simplified approach: we assume full write or error.
        self.write(subdata)
        return subdata.count
    }
}
