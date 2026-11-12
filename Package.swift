// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Overlays",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Overlays", targets: ["Overlays"]),
        .library(name: "OverlaysSwiftUI", targets: ["OverlaysSwiftUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/maazsurti/SimpleRouter.git", from: "1.1.0"),
    ],
    targets: [
        .target(name: "Overlays"),
        .target(
            name: "OverlaysSwiftUI",
            dependencies: [.product(name: "SimpleRouterSwiftUI", package: "SimpleRouter")]
        ),
        .testTarget(name: "OverlaysTests", dependencies: ["Overlays"]),
        .testTarget(name: "OverlaysSwiftUITests", dependencies: ["OverlaysSwiftUI"]),
    ],
    swiftLanguageModes: [.v5]
)
