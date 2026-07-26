// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SplitwiseApp",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SplitwiseApp",
            targets: ["SplitwiseApp"]
        )
    ],
    targets: [
        .target(
            name: "SplitwiseApp",
            path: "SplitwiseApp",
            exclude: [
                "App/Info.plist"
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
