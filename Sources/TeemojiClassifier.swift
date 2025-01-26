//
// TeemojiClassifier.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, visionOS 1.0, *)
class TeemojiClassifierInput : MLFeatureProvider {

    /// Input text as string value
    var text: String

    var featureNames: Set<String> { ["text"] }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "text" {
            return MLFeatureValue(string: text)
        }
        return nil
    }

    init(text: String) {
        self.text = text
    }

}


/// Model Prediction Output Type
@available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, visionOS 1.0, *)
class TeemojiClassifierOutput : MLFeatureProvider {

    /// Source provided by CoreML
    private let provider : MLFeatureProvider

    /// Text label as string value
    var label: String {
        provider.featureValue(for: "label")!.stringValue
    }

    var featureNames: Set<String> {
        provider.featureNames
    }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        provider.featureValue(for: featureName)
    }

    init(label: String) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["label" : MLFeatureValue(string: label)])
    }

    init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, visionOS 1.0, *)
class TeemojiClassifier {
    let model: MLModel

    /// URL of model assuming it was installed in the same bundle as this class
    class var urlOfModelInThisBundle : URL {
        let bundle = Bundle(for: self)
        return bundle.url(forResource: "TeemojiClassifier", withExtension:"mlmodelc")!
    }

    /**
        Construct TeemojiClassifier instance with an existing MLModel object.

        Usually the application does not use this initializer unless it makes a subclass of TeemojiClassifier.
        Such application may want to use `MLModel(contentsOfURL:configuration:)` and `TeemojiClassifier.urlOfModelInThisBundle` to create a MLModel object to pass-in.

        - parameters:
          - model: MLModel object
    */
    init(model: MLModel) {
        self.model = model
    }

    /**
        Construct TeemojiClassifier instance by automatically loading the model from the app's bundle.
    */
    @available(*, deprecated, message: "Use init(configuration:) instead and handle errors appropriately.")
    convenience init() {
        try! self.init(contentsOf: type(of:self).urlOfModelInThisBundle)
    }

    /**
        Construct a model with configuration

        - parameters:
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    convenience init(configuration: MLModelConfiguration) throws {
        try self.init(contentsOf: type(of:self).urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct TeemojiClassifier instance with explicit path to mlmodelc file
        - parameters:
           - modelURL: the file url of the model

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL) throws {
        try self.init(model: MLModel(contentsOf: modelURL))
    }

    /**
        Construct a model with URL of the .mlmodelc directory and configuration

        - parameters:
           - modelURL: the file url of the model
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL, configuration: MLModelConfiguration) throws {
        try self.init(model: MLModel(contentsOf: modelURL, configuration: configuration))
    }

    /**
        Construct TeemojiClassifier instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
    class func load(configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<TeemojiClassifier, Error>) -> Void) {
        load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration, completionHandler: handler)
    }

    /**
        Construct TeemojiClassifier instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
    */
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    class func load(configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> TeemojiClassifier {
        try await load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct TeemojiClassifier instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<TeemojiClassifier, Error>) -> Void) {
        MLModel.load(contentsOf: modelURL, configuration: configuration) { result in
            switch result {
            case .failure(let error):
                handler(.failure(error))
            case .success(let model):
                handler(.success(TeemojiClassifier(model: model)))
            }
        }
    }

    /**
        Construct TeemojiClassifier instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
    */
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> TeemojiClassifier {
        let model = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
        return TeemojiClassifier(model: model)
    }

    /**
        Make a prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as TeemojiClassifierInput

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as TeemojiClassifierOutput
    */
    func prediction(input: TeemojiClassifierInput) throws -> TeemojiClassifierOutput {
        try prediction(input: input, options: MLPredictionOptions())
    }

    /**
        Make a prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as TeemojiClassifierInput
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as TeemojiClassifierOutput
    */
    func prediction(input: TeemojiClassifierInput, options: MLPredictionOptions) throws -> TeemojiClassifierOutput {
        let outFeatures = try model.prediction(from: input, options: options)
        return TeemojiClassifierOutput(features: outFeatures)
    }

    /**
        Make an asynchronous prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as TeemojiClassifierInput
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as TeemojiClassifierOutput
    */
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    func prediction(input: TeemojiClassifierInput, options: MLPredictionOptions = MLPredictionOptions()) async throws -> TeemojiClassifierOutput {
        let outFeatures = try await model.prediction(from: input, options: options)
        return TeemojiClassifierOutput(features: outFeatures)
    }

    /**
        Make a prediction using the convenience interface

        It uses the default function if the model has multiple functions.

        - parameters:
            - text: Input text as string value

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as TeemojiClassifierOutput
    */
    func prediction(text: String) throws -> TeemojiClassifierOutput {
        let input_ = TeemojiClassifierInput(text: text)
        return try prediction(input: input_)
    }

    /**
        Make a batch prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - inputs: the inputs to the prediction as [TeemojiClassifierInput]
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as [TeemojiClassifierOutput]
    */
    func predictions(inputs: [TeemojiClassifierInput], options: MLPredictionOptions = MLPredictionOptions()) throws -> [TeemojiClassifierOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results : [TeemojiClassifierOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result =  TeemojiClassifierOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}
