// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RepCoachCore",
    platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v14)],
    products: [
        .library(name: "RepCoachCore", targets: ["RepCoachCore"])
    ],
    targets: [
        .target(
            name: "RepCoachCore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "RepCoachCoreTests",
            dependencies: ["RepCoachCore"],
            resources: [.process("Fixtures")]
        )
    ]
)
