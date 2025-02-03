import CoreML
import Foundation

/// The main entry point for the Teemoji command-line tool.
///
/// This `@main` struct orchestrates parsing command-line arguments, opening files in append or write modes,
/// loading the `TeemojiClassifier` model, reading lines from standard input, and writing them (with an emoji) to
/// standard output and each specified file.
@main
struct Teemoji {
    struct ArgumentOptions {
        let append: Bool
        let fileURLs: [URL]
        let shouldExit: Bool
    }

    static func parseArguments() -> ArgumentOptions {
        var arguments = CommandLine.arguments
        arguments.removeFirst()

        let appendFlagIndex = arguments.firstIndex(where: { $0 == "-a" || $0 == "--append" })
        let ignoreSigIntIndex = arguments.firstIndex(where: { $0 == "-i" })
        let helpFlagIndex = arguments.firstIndex(where: { $0 == "-h" || $0 == "--help" })

        let append = (appendFlagIndex != nil)
        if let index = appendFlagIndex {
            arguments.remove(at: index)
        }

        if let index = ignoreSigIntIndex {
            signal(SIGINT, SIG_IGN)
            arguments.remove(at: index)
        }

        if helpFlagIndex != nil {
            printUsage()
            exit(EXIT_SUCCESS)
        }

        return ArgumentOptions(
            append: append,
            fileURLs: arguments.map { URL(fileURLWithPath: $0) },
            shouldExit: helpFlagIndex != nil
        )
    }

    static func openFileHandles(urls: [URL], append: Bool) -> ([(URL, FileHandle)], Int32) {
        var fileHandles: [(URL, FileHandle)] = []
        var exitStatus: Int32 = 0

        for url in urls {
            do {
                if append {
                    if !FileManager.default.fileExists(atPath: url.path) {
                        FileManager.default.createFile(atPath: url.path, contents: nil)
                    }
                    let handle = try FileHandle(forWritingTo: url)
                    try handle.seekToEnd()
                    fileHandles.append((url, handle))
                } else {
                    FileManager.default.createFile(atPath: url.path, contents: nil)
                    let handle = try FileHandle(forWritingTo: url)
                    fileHandles.append((url, handle))
                }
            } catch {
                fputs("teemoji: cannot open \(url.path): \(error)\n", stderr)
                exitStatus = 1
            }
        }
        return (fileHandles, exitStatus)
    }

    static func loadModel() -> TeemojiClassifier? {
        guard
            let modelURL = Bundle.module.url(
                forResource: "TeemojiClassifier", withExtension: "mlmodelc"),
            let rawModel = try? MLModel(contentsOf: modelURL)
        else {
            fputs("teemoji: failed to load CoreML model.\n", stderr)
            return nil
        }
        return TeemojiClassifier(model: rawModel)
    }

    static func writeToFiles(outputLine: String, fileHandles: [(URL, FileHandle)]) -> Int32 {
        var exitStatus: Int32 = 0

        if let data = outputLine.data(using: .utf8) {
            for (url, handle) in fileHandles {
                var offset = 0
                let length = data.count
                while offset < length {
                    do {
                        let sliceSize = try handle.writeCompat(
                            data: data, offset: offset, length: length - offset)
                        if sliceSize <= 0 {
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
        return exitStatus
    }

    static func main() {
        let options = parseArguments()
        if options.shouldExit { return }

        let (fileHandles, initialExitStatus) = openFileHandles(
            urls: options.fileURLs, append: options.append)
        var exitStatus = initialExitStatus

        defer {
            for (_, handle) in fileHandles {
                try? handle.close()
            }
        }

        guard let model = loadModel() else {
            exit(EXIT_FAILURE)
        }

        while let line = readLine() {
            let predictionLabel: String
            do {
                let prediction = try model.prediction(text: line)
                predictionLabel = prediction.label
            } catch {
                predictionLabel = "❓"
            }

            let outputLine = "\(predictionLabel) \(line)\n"
            if fputs(outputLine, stdout) < 0 {
                exitStatus = 1
            }

            exitStatus = max(
                exitStatus, writeToFiles(outputLine: outputLine, fileHandles: fileHandles))
        }

        exit(exitStatus)
    }

    /// Prints usage, matching FreeBSD tee's style.
    static func printUsage() {
        let usage = """
            usage: teemoji [-ai] [file ...]

            Reads from standard input, writes to standard output and specified files, prepending an emoji
            inferred by a Core ML model to each line. Options:
              -a\tAppend to the given file(s), do not overwrite
              -i\tIgnore SIGINT
              -h\tDisplay help (non-standard extension)
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
        // We'll try writing all subdata at once. If it succeeds, it's done.
        // If it fails, we throw.
        // This is a simplified approach: we assume full write or error.
        self.write(subdata)
        return subdata.count
    }
}
