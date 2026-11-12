// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Overlays",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Overlays", targets: ["Overlays"]),
    ],
    targets: [
        .target(name: "Overlays"),
        .testTarget(name: "OverlaysTests", dependencies: ["Overlays"]),
    ],
    swiftLanguageModes: [.v5]
)
