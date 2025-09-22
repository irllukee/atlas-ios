// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Atlas",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Atlas",
            targets: ["Atlas"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/wordpress-mobile/AztecEditor-iOS",
            .upToNextMajor(from: "1.20.0")
        ),
    ],
    targets: [
        .target(
            name: "Atlas",
            dependencies: [
                .product(name: "Aztec", package: "AztecEditor-iOS"),
                .product(name: "WordPressEditor", package: "AztecEditor-iOS"),
            ]
        ),
    ]
)
