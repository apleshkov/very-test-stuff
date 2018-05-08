// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Parser",
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.21.0")
    ],
    targets: [
        .target(
            name: "Parser",
            dependencies: []
        ),
        .testTarget(
            name: "ParserTests",
            dependencies: ["Parser"]
        )
    ]
)
