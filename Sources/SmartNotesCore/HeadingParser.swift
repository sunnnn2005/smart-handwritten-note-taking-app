import Foundation

public struct ParsedHeading: Equatable, Sendable {
    public let title: String
    public let rawText: String

    public init(title: String, rawText: String) {
        self.title = title
        self.rawText = rawText
    }
}

public enum HeadingParser {
    public static func parse(from recognizedLines: [String]) -> ParsedHeading? {
        recognizedLines
            .map(normalize)
            .compactMap(extractHeading)
            .first
    }

    public static func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "＃", with: "#")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractHeading(from line: String) -> ParsedHeading? {
        guard line.hasPrefix("#") else {
            return nil
        }

        let title = line
            .dropFirst()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            return nil
        }

        return ParsedHeading(title: title, rawText: line)
    }
}
