import Foundation
import PencilKit
@preconcurrency import Vision
import UIKit
import SmartNotesCore

enum HeadingRecognizer {
    static func recognizeHeadings(from drawing: PKDrawing, completion: @escaping @Sendable ([ParsedHeading], String?) -> Void) {
        guard !drawing.bounds.isNull, !drawing.bounds.isEmpty else {
            completion([], "No handwriting found on this page.")
            return
        }

        guard let image = imageForOCR(from: drawing) else {
            completion([], "Could not prepare handwriting for scanning.")
            return
        }

        guard let cgImage = image.cgImage else {
            completion([], "Could not prepare handwriting for scanning.")
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error {
                DispatchQueue.main.async {
                    completion([], error.localizedDescription)
                }
                return
            }

            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let candidates = observations.compactMap { $0.topCandidates(1).first?.string }
            let headings = HeadingParser.parseAll(from: candidates)

            DispatchQueue.main.async {
                completion(headings, nil)
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion([], error.localizedDescription)
                }
            }
        }
    }

    private static func imageForOCR(from drawing: PKDrawing) -> UIImage? {
        let bounds = drawing.bounds.standardized
        guard bounds.width > 1, bounds.height > 1 else {
            return nil
        }

        let paddedBounds = bounds.insetBy(dx: -48, dy: -48)
        let maxDimension: CGFloat = 1400
        let largestSide = max(paddedBounds.width, paddedBounds.height)
        let scale = max(0.5, min(2.0, maxDimension / largestSide))
        let outputSize = CGSize(
            width: max(1, paddedBounds.width * scale),
            height: max(1, paddedBounds.height * scale)
        )

        let drawingImage = drawing.image(from: paddedBounds, scale: scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: outputSize, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: outputSize))
            drawingImage.draw(in: CGRect(origin: .zero, size: outputSize))
        }
    }
}
