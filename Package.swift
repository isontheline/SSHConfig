// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SSHConfig",
  products: [
    .library(
      name: "SSHConfig",
      targets: ["SSHConfig"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "SSHConfig",
      dependencies: []),
    .testTarget(
      name: "SSHConfigTests",
      dependencies: ["SSHConfig"],
      resources: [
        .copy("testdata")
      ]
    ),
  ]
)
