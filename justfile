# List available tasks
default:
    just --list

# Build teemoji
build mode="debug":
    xcrun coremlcompiler generate Resources/TeemojiClassifier.mlpackage Sources --language Swift
    xcrun coremlcompiler compile Resources/TeemojiClassifier.mlpackage Sources
    swift build --configuration {{mode}} --verbose --disable-sandbox --arch arm64 --arch x86_64

test: (build "debug")
    swift test
