# Variables
modelPath := "Resources/TeemojiClassifier.mlproj/Models/TeemojiClassifier.mlmodel"

# List available tasks
default:
    just --list

# Build teemoji
build mode="debug":
    xcrun coremlcompiler generate {{modelPath}} Sources --language Swift
    xcrun coremlcompiler compile {{modelPath}} Sources
    swift build --configuration {{mode}} --verbose --disable-sandbox --arch arm64 --arch x86_64

test: (build "debug")
    swift test
