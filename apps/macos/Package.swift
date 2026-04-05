// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OrbitCalendarMac",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "OrbitCalendarMac", targets: ["OrbitCalendarMac"]),
    ],
    targets: [
        .executableTarget(
            name: "OrbitCalendarMac",
            path: "Sources"
        ),
    ]
)
