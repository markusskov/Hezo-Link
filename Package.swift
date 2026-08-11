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
    .target(
      name: "HezoLinkCore",
      swiftSettings: [.treatAllWarnings(as: .error)]
    ),
    .testTarget(
      name: "HezoLinkCoreTests",
      dependencies: ["HezoLinkCore"],
      swiftSettings: [.treatAllWarnings(as: .error)]
    ),
  ],
  swiftLanguageModes: [.v6]
)
