This directory previously contained a placeholder Xcode project file (`project.pbxproj`).

For the MVP, the project is built using Swift Package Manager. Xcode 15 and later can open `Package.swift` directly to work with the project.

If you need a traditional `.xcodeproj`, generate it from the package using:

```bash
swift package generate-xcodeproj
```

The generated project will appear in the repository root as `Brisa.xcodeproj`.