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

    func testIgnoresEmptyHeadingMarker() {
        let heading = HeadingParser.parse(from: ["#   "])

        XCTAssertNil(heading)
    }

    func testIgnoresLinesWithoutHeadingMarker() {
        let heading = HeadingParser.parse(from: ["Lecture 1", "ordinary notes"])

        XCTAssertNil(heading)
    }
}
