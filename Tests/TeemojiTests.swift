import XCTest

import class Foundation.Bundle

final class TeemojiTests: XCTestCase {
    func runTeemoji(inputs: [String], arguments: [String] = []) throws -> String {
        let teemojiBinary = productsDirectory.appendingPathComponent("teemoji")

        let process = Process()
        process.executableURL = teemojiBinary
        process.arguments = arguments

        let inputPipe = Pipe()
        let outputPipe = Pipe()

        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        // Start the process
        try process.run()

        // Write input lines
        let inputHandle = inputPipe.fileHandleForWriting
        for input in inputs {
            inputHandle.write(input.data(using: .utf8)!)
        }
        inputHandle.closeFile()

        // Read all output (stdout + stderr combined)
        let outputData: Data
        do {
            outputData = try outputPipe.fileHandleForReading.readToEnd() ?? Data()
        }

        // Wait for the process to finish
        process.waitUntilExit()

        // Throw an error if the process's exit code was non-zero
        if process.terminationStatus != 0 {
            throw NSError(
                domain: "TeemojiError", code: Int(process.terminationStatus),
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Teemoji process failed with exit code \(process.terminationStatus)."
                ])
        }

        // Convert output data to string
        return String(data: outputData, encoding: .utf8) ?? ""
    }

    func testBasicEmojiPrediction() throws {
        let input = "Hello World"
        let output = try runTeemoji(inputs: [input])

        // The output should contain our input text.
        XCTAssertTrue(
            output.contains(input),
            "Output should contain the original input text: \(input)")

        // Check that the line is not simply echoed back (i.e., we expect some prepended emoji or fallback).
        // One simple check: it should not start exactly with the input text alone (plus a newline).
        XCTAssertFalse(
            output.starts(with: "\(input)\n"),
            "Output should not start directly with the input, it should have an emoji prefix.")
    }

    func testHelpOption() throws {
        let output = try runTeemoji(inputs: [], arguments: ["-h"])
        XCTAssertTrue(output.contains("usage: teemoji"), "Output should contain usage instructions")
    }

    func testAppendFlag() throws {
        // Setup: Create and write to a temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test_append.txt")
        try "Initial Content\n".write(to: tempFile, atomically: true, encoding: .utf8)

        // Run teemoji with the -a flag to append
        _ = try runTeemoji(inputs: ["Appending Content\n"], arguments: ["-a", tempFile.path])

        // Verify: The file should contain both the initial and appended content
        let fileContent = try String(contentsOf: tempFile)
        XCTAssertTrue(fileContent.contains("Initial Content"))
        XCTAssertTrue(fileContent.contains("Appending Content"))
    }

    func testReverseOption() throws {
        let input = "Hello World"
        let output = try runTeemoji(inputs: [input], arguments: ["-r"])

        // Verify the output starts with the input text
        XCTAssertTrue(
            output.starts(with: input),
            "With the reverse option enabled, the output should begin with the original input text.")

        // Verify the output has changed
        XCTAssertFalse(
            output.starts(with: "\(input)\n"),
            "Output should not end directly with the input, it should have an emoji suffix.")
    }

    func testIgnoreSigInt() throws {
        // Simulate sending SIGINT using a process group or similar to make sure it's ignored
        // Note: This test requires specific setup and may not be fully feasible in some test environments
    }

    func testFileWriting() throws {
        // Temp file setup
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test_output.txt")

        // Run teemoji specifying output file
        _ = try runTeemoji(inputs: ["Output Test\n"], arguments: [tempFile.path])

        // Validate that content was written to the temp file
        let fileContent = try String(contentsOf: tempFile)
        XCTAssertTrue(fileContent.contains("Output Test"))
    }

    func testInvalidFile() throws {
        // Use an invalid file path to test error handling
        do {
            _ = try runTeemoji(inputs: ["Some Content"], arguments: ["/invalid/path/nope.txt"])
            XCTFail("Expected error when trying to write to an invalid path")
        } catch {
            // Expected behavior
        }
    }

    func testEmptyInput() throws {
        // Ensure the program handles empty input gracefully
        let output = try runTeemoji(inputs: ["\n"])
        // The output shouldn't be completely empty if the program prepends an emoji/fallback.
        // But at minimum, we confirm it doesn't crash or produce an error.
        XCTAssertFalse(
            output.isEmpty, "Output should not be entirely empty even if input is empty.")
    }

    func testFallbackOnModelFailure() throws {
        // To accurately test model failure, you might temporarily rename or remove the model file,
        // or mock the model. Here you could do something like forcing the code to supply non-UTF8 input,
        // or removing the mlmodelc resource so that loading fails. For example:
        //
        // 1. Temporarily rename the TeemojiClassifier.mlmodelc folder before running the test.
        // 2. Run teemoji. The code will catch an error and use the fallback "❓".
        //
        // Ensure output is the fallback emoji when prediction fails.
        // This is left as an exercise, depending on your build/test environment.
    }

    func testPartialWrites() throws {
        // This would require mocking or controlling the FileHandle to simulate partial writes,
        // since normally all data is written at once on Apple platforms.
        // You could use a custom FileHandle subclass or something akin to that, but it’s more advanced.
    }
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
