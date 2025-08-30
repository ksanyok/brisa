// swift-tools-version:5.9
import PackageDescription

// Package manifest for the Brisa project.  
// This manifest defines the executable target that builds the macOS application and a test target.
let package = Package(
    name: "Brisa",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "BrisaApp",
            targets: ["BrisaApp"]
        ),
    ],
    dependencies: [
        // Declare any external package dependencies here.  
        // For the MVP we do not require third‑party Swift packages.
    ],
    targets: [
        // The main executable target containing all source files for the application.
        .executableTarget(
            name: "BrisaApp",
            dependencies: [],
            path: "BrisaApp/Sources"
        ),
        // A combined test target for unit and integration tests.  
        .testTarget(
            name: "BrisaAppTests",
            dependencies: ["BrisaApp"],
            path: "BrisaApp/Tests"
        ),
    ]
)