import XCTest

@testable import SmartNotesCore

final class HeadingParserTests: XCTestCase {
    func testParsesHashPrefixedHeading() {
        let heading = HeadingParser.parse(from: ["random note", "# Regression Analysis"])

        XCTAssertEqual(heading, ParsedHeading(title: "Regression Analysis", rawText: "# Regression Analysis"))
    }

    func testTrimsWhitespaceAroundHeading() {
        let heading = HeadingParser.parse(from: ["   # Lecture 5   "])

        XCTAssertEqual(heading?.title, "Lecture 5")
    }

    func testSupportsFullWidthHashFromHandwritingOCR() {
        let heading = HeadingParser.parse(from: ["＃ Probability Theory"])

        XCTAssertEqual(heading?.title, "Probability Theory")
    }

    func testSupportsMusicalSharpOcrFallback() {
        let heading = HeadingParser.parse(from: ["♯ Linear Algebra"])

        XCTAssertEqual(heading?.title, "Linear Algebra")
    }

    func testParsesHeadingLevels() {
        let heading = HeadingParser.parse(from: ["### Model Evaluation"])

        XCTAssertEqual(heading?.title, "Model Evaluation")
        XCTAssertEqual(heading?.level, 3)
    }

    func testParseAllReturnsMultipleHeadingsInOrder() {
        let headings = HeadingParser.parseAll(from: ["# Data Cleaning", "notes", "## Outliers"])

        XCTAssertEqual(headings.map(\.title), ["Data Cleaning", "Outliers"])
        XCTAssertEqual(headings.map(\.level), [1, 2])
    }

    func testIgnoresEmptyHeadingMarker() {
        let heading = HeadingParser.parse(from: ["#   "])

        XCTAssertNil(heading)
    }

    func testIgnoresLinesWithoutHeadingMarker() {
        let heading = HeadingParser.parse(from: ["Lecture 1", "ordinary notes"])

        XCTAssertNil(heading)
    }
}
