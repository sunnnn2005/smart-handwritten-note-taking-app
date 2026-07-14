import Foundation
import PencilKit
import Vision
import UIKit

enum HeadingRecognizer {
    static func recognizeHeading(from drawing: PKDrawing, completion: @escaping (String?) -> Void) {
        let image = drawing.image(from: drawing.bounds, scale: 2.0)
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        let request = VNRecognizeTextRequest { request, _ in
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let candidates = observations.compactMap { $0.topCandidates(1).first?.string }
            let heading = candidates
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { $0.hasPrefix("#") }
                .map { String($0.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines) }

            DispatchQueue.main.async {
                completion(heading?.isEmpty == false ? heading : nil)
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage)
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
