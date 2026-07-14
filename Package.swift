// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SmartHandwrittenNotes",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "SmartNotesCore",
            targets: ["SmartNotesCore"]
        )
    ],
    targets: [
        .target(
            name: "SmartNotesCore"
        ),
        .testTarget(
            name: "SmartNotesCoreTests",
            dependencies: ["SmartNotesCore"]
        )
    ]
)
