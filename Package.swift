// swift-tools-version: 5.9
import PackageDescription

// Runs the same core sources and tests on macOS without an iOS Simulator.
let package = Package(
    name: "CheckoutCore",
    platforms: [.macOS(.v13)],
    products: [.library(name: "CheckoutCore", targets: ["CheckoutCore"])],
    targets: [
        .target(name: "CheckoutCore", path: "CheckoutPractice/Features/Checkout",
                exclude: ["Views"],
                sources: ["Models", "Services", "Persistence", "ViewModels"]),
        .testTarget(name: "CheckoutCoreTests", dependencies: ["CheckoutCore"], path: "CheckoutPracticeTests")
    ]
)
