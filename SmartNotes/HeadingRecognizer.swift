import Foundation
import PencilKit
import Vision
import UIKit
import SmartNotesCore

enum HeadingRecognizer {
    static func recognizeHeading(from drawing: PKDrawing, completion: @escaping (ParsedHeading?) -> Void) {
        let image = drawing.image(from: drawing.bounds, scale: 2.0)
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        let request = VNRecognizeTextRequest { request, _ in
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let candidates = observations.compactMap { $0.topCandidates(1).first?.string }
            let heading = HeadingParser.parse(from: candidates)

            DispatchQueue.main.async {
                completion(heading)
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
