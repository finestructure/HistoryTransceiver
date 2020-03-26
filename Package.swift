// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HistoryTransceiver",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "HistoryTransceiver",
            targets: ["HistoryTransceiver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/swift-composable-architecture", .revision("dd300672fbb96495a725729d2b0cac69e2855979")),
        .package(url: "https://github.com/insidegui/MultipeerKit", from: "0.1.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "HistoryTransceiver",
            dependencies: ["ComposableArchitecture", "MultipeerKit"]),
    ]
)
