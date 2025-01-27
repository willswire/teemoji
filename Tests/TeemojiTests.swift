import XCTest

import class Foundation.Bundle

final class TeemojiTests: XCTestCase {
    /// Helper function to run the Teemoji executable with given input and arguments.
    func runTeemoji(input: String, arguments: [String] = []) throws -> String {
        let teemojiBinary = productsDirectory.appendingPathComponent("teemoji")

        let process = Process()
        process.executableURL = teemojiBinary
        process.arguments = arguments

        let inputPipe = Pipe()
        let outputPipe = Pipe()

        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()

        // Send the input to the process
        let inputHandle = inputPipe.fileHandleForWriting
        inputHandle.write(input.data(using: .utf8)!)
        inputHandle.closeFile()

        // Read the output
        if let outputData = try outputPipe.fileHandleForReading.readToEnd() {
            return String(data: outputData, encoding: .utf8) ?? "UNKNOWN"
        } else {
            return "UNKNOWN"
        }
    }

    func testBasicEmojiPrediction() throws {
        let input = "Hello World"
        let output = try runTeemoji(input: input)
        // Adjust the test to allow for any predicted emoji
        XCTAssertTrue(output.contains("🌍 Hello World"), "Output should contain: Hello World")
    }

    func testHelpOption() throws {
        let output = try runTeemoji(input: "", arguments: ["-h"])  // Ensure correct flag
        XCTAssertTrue(output.contains("Usage: teemoji"), "Output should contain usage instructions")
    }

    // Additional tests could include checking append behavior, etc.
}

/// Returns path to the built products directory.
var productsDirectory: URL {
    #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
    #else
        return Bundle.main.bundleURL
    #endif
}
