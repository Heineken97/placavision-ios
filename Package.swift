// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Placavision",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "Placavision", targets: ["Placavision"])
    ],
    targets: [
        .target(
            name: "Placavision",
            path: "Sources/Placavision",
            sources: [
                "Models",
                "Services/Auth",
                "Utils",
                "data"
            ]
        ),
        .testTarget(
            name: "PlacavisionTests",
            dependencies: ["Placavision"],
            path: "Tests/PlacavisionTests"
        )
    ]
)
