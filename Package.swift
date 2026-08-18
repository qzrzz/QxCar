// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "QxCar",
    defaultLocalization: "zh-Hans",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "QxCar", targets: ["QxCar"]),
        .library(name: "QxCarCore", targets: ["QxCarCore"])
    ],
    targets: [
        .target(
            name: "QxCarCoreBridge",
            path: "Sources/QxCarCoreBridge",
            publicHeadersPath: "include"
        ),
        .target(
            name: "QxCarCore",
            dependencies: ["QxCarCoreBridge"],
            path: "Sources/QxCarCore"
        ),
        .executableTarget(
            name: "QxCar",
            dependencies: ["QxCarCore"],
            path: "Sources/QxCar",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "QxCarCoreTests",
            dependencies: ["QxCarCore"],
            path: "Tests/QxCarCoreTests"
        )
    ]
)
