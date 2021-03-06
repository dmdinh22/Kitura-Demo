// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KituraDemo",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/IBM-Swift/Kitura.git", from: "2.0.0"),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", from: "1.8.0"),
        .package(url: "https://github.com/dmdinh22/KituraFirefoxDetector.git", from: "0.0.1"),
        .package(url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", from: "1.11.0"),
        // use v1.1.0 to use Swift-Kuery 2.0.0 to follow along tutorial
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery-SQLite.git", from: "1.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "KituraDemo",
            dependencies: ["Kitura", "HeliumLogger", "KituraFirefoxDetector", "KituraStencil", "SwiftKuerySQLite"]),
        .testTarget(
            name: "KituraDemoTests",
            dependencies: ["KituraDemo"]),
    ]
)
