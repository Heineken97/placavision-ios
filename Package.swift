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
                "Config/APIConfig.swift",
                "Config/ServerConfig.swift",
                "Data/APIService.swift",
                "Data/Repository.swift",
                "Models/User.swift",
                "Models/Report.swift",
                "Models/GpsResponse.swift",
                "Services/Auth/AuthService.swift",
                "Utils/FileHelper.swift",
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PlacavisionTests",
            dependencies: ["Placavision"],
            path: "Tests/PlacavisionTests"
        )
    ]
)
