import Vision
import UIKit
import Combine

// MARK: - Prediction Model
struct FoodPrediction: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Float
}

// MARK: - ViewModel
class FoodDetectorViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var predictions: [FoodPrediction] = []
    @Published var isClassifying = false
    @Published var errorMessage: String?

    private let classifier = FoodClassifier()

    func classify() {
        guard let image = selectedImage else { return }
        isClassifying = true
        predictions = []
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.classifier.classify(image: image) { results, error in
                DispatchQueue.main.async {
                    self?.isClassifying = false
                    if let error = error {
                        self?.errorMessage = error
                    } else {
                        self?.predictions = results
                    }
                }
            }
        }
    }
}

// MARK: - CoreML Classifier (no TFLite needed!)
class FoodClassifier {

    private var model: VNCoreMLModel?

    init() {
        setupModel()
    }

    private func setupModel() {
        // Uses the MobileNetV2.mlmodel you added to the project
        guard let coreMLModel = try? MobileNetV2(configuration: MLModelConfiguration()).model,
              let vnModel = try? VNCoreMLModel(for: coreMLModel) else {
            print("❌ Failed to load CoreML model")
            return
        }
        self.model = vnModel
        print("✅ CoreML model loaded successfully!")
    }

    func classify(image: UIImage, completion: @escaping ([FoodPrediction], String?) -> Void) {
        guard let model = model else {
            completion([], "Model not loaded. Make sure MobileNetV2.mlmodel is added to the project.")
            return
        }

        guard let cgImage = image.cgImage else {
            completion([], "Could not process image.")
            return
        }

        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                completion([], "Classification failed: \(error.localizedDescription)")
                return
            }

            guard let results = request.results as? [VNClassificationObservation] else {
                completion([], "No results found.")
                return
            }

            // Take top 5 results
            let top5 = results.prefix(5).map { obs in
                // Clean up label: "Granny Smith" or "pizza, pizza pie" → "Pizza"
                let cleanLabel = obs.identifier
                    .components(separatedBy: ",").first?
                    .trimmingCharacters(in: .whitespaces)
                    .capitalized ?? obs.identifier
                return FoodPrediction(label: cleanLabel, confidence: obs.confidence)
            }

            completion(Array(top5), nil)
        }

        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion([], "Failed to perform classification: \(error.localizedDescription)")
        }
    }
}
