// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Zara-Trigger",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Zara-Trigger",
            targets: ["Zara-Trigger"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(path: "../Common"),
        .package(path: "../Zara-Logger"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.11.0"),

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "Zara-Trigger", dependencies: ["Common", "Zara-Logger", 
            .product(name: "NIO", package: "swift-nio")]
        ),
        .testTarget(
            name: "Zara-TriggerTests",
            dependencies: ["Zara-Trigger"]),
    ]
)
