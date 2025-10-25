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
                "config/APIConfig.swift",
                "config/ServerConfig.swift",
                "data/APIService.swift",
                "data/Repository.swift",
                "models/User.swift",
                "models/Report.swift",
                "models/GpsResponse.swift",
                "services/auth/AuthService.swift",
                "utils/FileHelper.swift",
            ],
            resources: [
                .process("resources")
            ]
        ),
        .testTarget(
            name: "PlacavisionTests",
            dependencies: ["Placavision"],
            path: "Tests/PlacavisionTests"
        )
    ]
)
