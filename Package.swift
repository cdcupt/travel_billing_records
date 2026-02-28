// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TravelBillingRecords",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "TravelBillingCore", targets: ["TravelBillingCore"])
    ],
    targets: [
        .target(
            name: "TravelBillingCore",
            dependencies: []
        ),
        .testTarget(
            name: "TravelBillingCoreTests",
            dependencies: ["TravelBillingCore"]
        )
    ]
)
