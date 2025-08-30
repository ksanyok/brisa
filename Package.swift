// swift-tools-version:5.9
import PackageDescription

// Brisa is implemented as a single executable target. The package
// manifest does not declare any external dependencies for the MVP. Tests
// live in a separate target.
let package = Package(
    name: "Brisa",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "BrisaApp",
            targets: ["BrisaApp"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "BrisaApp",
            dependencies: [],
            path: "BrisaApp/Sources"
        ),
        .testTarget(
            name: "BrisaAppTests",
            dependencies: ["BrisaApp"],
            path: "BrisaApp/Tests"
        )
    ]
)