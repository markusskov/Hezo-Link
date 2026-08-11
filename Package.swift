// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "HezoLink",
  platforms: [
    .iOS(.v26),
    .macOS(.v15),
  ],
  products: [
    .library(name: "HezoLinkCore", targets: ["HezoLinkCore"])
  ],
  targets: [
    .target(name: "HezoLinkCore"),
    .testTarget(name: "HezoLinkCoreTests", dependencies: ["HezoLinkCore"]),
  ],
  swiftLanguageModes: [.v6]
)
