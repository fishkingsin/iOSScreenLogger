// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iOSScreenLogger",
    platforms: [.iOS(.v12), .macCatalyst(.v13), .macOS(.v10_13), .tvOS(.v12), .watchOS(.v7)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "iOSScreenLogger",
            targets: ["iOSScreenLogger"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "iOSScreenLogger"),
        .testTarget(
            name: "iOSScreenLoggerTests",
            dependencies: ["iOSScreenLogger"]),
    ]
)
