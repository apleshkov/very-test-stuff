// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Saber",
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.21.0")
    ],
    targets: [
        .target(
            name: "Saber",
            dependencies: ["SourceKittenFramework"]),
        .testTarget(
            name: "SaberTests",
            dependencies: ["Saber"])
    ]
)
