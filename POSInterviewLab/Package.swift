// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "POSCore", platforms: [.iOS(.v16), .macOS(.v13)], products: [.library(name: "POSCore", targets: ["POSCore"])], targets: [.target(name: "POSCore"), .testTarget(name: "POSCoreTests", dependencies: ["POSCore"])])
