import Foundation
import Vision
#if canImport(UIKit)
import UIKit
#endif

public struct OCRResult: Sendable {
    public let isSuccess: Bool
    public let recognizedText: String
    public let confidence: Float
    public let clues: [PlaceClue]
    public let explicitCoordinates: ExtractedCoordinateResult?
    public let errorMessage: String?
}

/// On-device screenshot and photo reader using Apple's Vision framework.
public final class VisionOCRService: @unchecked Sendable {
    public static let shared = VisionOCRService()
    
    public init() {}
    
    #if canImport(UIKit)
    public func recognizeText(in image: UIImage) async -> OCRResult {
        guard let cgImage = image.cgImage else {
            return OCRResult(
                isSuccess: false,
                recognizedText: "",
                confidence: 0,
                clues: [],
                explicitCoordinates: nil,
                errorMessage: "Could not retrieve CGImage representation."
            )
        }
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        return await processCGImage(cgImage, orientation: orientation)
    }
    #endif
    
    public func recognizeText(in imageData: Data) async -> OCRResult {
        #if canImport(UIKit)
        guard let image = UIImage(data: imageData) else {
            return OCRResult(
                isSuccess: false,
                recognizedText: "",
                confidence: 0,
                clues: [],
                explicitCoordinates: nil,
                errorMessage: "Invalid image data format."
            )
        }
        return await recognizeText(in: image)
        #else
        return OCRResult(
            isSuccess: false,
            recognizedText: "",
            confidence: 0,
            clues: [],
            explicitCoordinates: nil,
            errorMessage: "UIKit not available."
        )
        #endif
    }
    
    #if canImport(UIKit)
    private func processCGImage(_ cgImage: CGImage, orientation: CGImagePropertyOrientation) async -> OCRResult {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(returning: OCRResult(
                        isSuccess: false,
                        recognizedText: "",
                        confidence: 0,
                        clues: [],
                        explicitCoordinates: nil,
                        errorMessage: error.localizedDescription
                    ))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    continuation.resume(returning: OCRResult(
                        isSuccess: true,
                        recognizedText: "",
                        confidence: 0,
                        clues: [],
                        explicitCoordinates: nil,
                        errorMessage: nil
                    ))
                    return
                }
                
                var recognizedLines: [String] = []
                var totalConfidence: Float = 0
                var count: Float = 0
                
                for obs in observations {
                    if let topCandidate = obs.topCandidates(1).first {
                        recognizedLines.append(topCandidate.string)
                        totalConfidence += topCandidate.confidence
                        count += 1
                    }
                }
                
                let fullText = recognizedLines.joined(separator: "\n")
                let avgConfidence = count > 0 ? (totalConfidence / count) : 0
                
                // 1. Check for coordinates in OCR text
                let coords = LinkExtractor.extractCoordinates(fromText: fullText)
                
                // 2. Extract place clues from recognized lines
                var clues: [PlaceClue] = []
                for line in recognizedLines {
                    let lineClues = LinkExtractor.extractPlaceNameCandidates(url: "", caption: line)
                    for clue in lineClues {
                        if !clues.contains(where: { $0.name.lowercased() == clue.name.lowercased() }) {
                            clues.append(PlaceClue(
                                name: clue.name,
                                source: "vision_ocr",
                                confidence: "high",
                                evidence: "Apple Vision recognized text \"\(clue.name)\" in screenshot"
                            ))
                        }
                    }
                }
                
                continuation.resume(returning: OCRResult(
                    isSuccess: true,
                    recognizedText: fullText,
                    confidence: avgConfidence,
                    clues: clues,
                    explicitCoordinates: coords,
                    errorMessage: nil
                ))
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "ja", "fr", "es", "de", "it"]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: OCRResult(
                    isSuccess: false,
                    recognizedText: "",
                    confidence: 0,
                    clues: [],
                    explicitCoordinates: nil,
                    errorMessage: error.localizedDescription
                ))
            }
        }
    }
    #endif
}

#if canImport(UIKit)
private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
#endif
