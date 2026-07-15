import Foundation

public struct ParsedHeading: Equatable, Sendable {
    public let title: String
    public let rawText: String
    public let level: Int

    public init(title: String, rawText: String, level: Int = 1) {
        self.title = title
        self.rawText = rawText
        self.level = level
    }
}

public typealias ParsedOutlineTag = ParsedHeading

public enum OutlineParser {
    public static func parse(from recognizedLines: [String]) -> ParsedHeading? {
        parseAll(from: recognizedLines).first
    }

    public static func parseAll(from recognizedLines: [String]) -> [ParsedHeading] {
        recognizedLines
            .map(normalize)
            .compactMap(extractHeading)
    }

    public static func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "＃", with: "#")
            .replacingOccurrences(of: "♯", with: "#")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func parseOutlineTag(from text: String) -> ParsedOutlineTag? {
        extractHeading(from: normalize(text))
    }

    private static func extractHeading(from line: String) -> ParsedHeading? {
        guard line.hasPrefix("#") else {
            return nil
        }

        let markerCount = line.prefix { $0 == "#" }.count
        guard markerCount > 0 && markerCount <= 3 else {
            return nil
        }

        let level = markerCount
        let title = line
            .dropFirst(markerCount)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            return nil
        }

        return ParsedHeading(title: title, rawText: line, level: level)
    }
}

public typealias HeadingParser = OutlineParser
