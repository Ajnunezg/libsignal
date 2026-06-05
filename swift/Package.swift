// swift-tools-version:6.0

//
// Copyright 2020-2021 Signal Messenger, LLC.
// SPDX-License-Identifier: AGPL-3.0-only
//

import PackageDescription
import Foundation

let rustBuildDir = "../target/debug/"
let packageRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let hasOpenBurnBarSignalFfiXCFramework = FileManager.default.fileExists(
    atPath: packageRoot
        .appendingPathComponent("../../OpenBurnBarSignalFfi.xcframework")
        .standardizedFileURL
        .path
)

let signalFfiBinaryTargets: [Target] = hasOpenBurnBarSignalFfiXCFramework ? [
    .binaryTarget(
        name: "OpenBurnBarLibSignalFfi",
        path: "../../OpenBurnBarSignalFfi.xcframework"
    )
] : []

let libSignalClientDependencies: [Target.Dependency] = hasOpenBurnBarSignalFfiXCFramework
    ? ["SignalFfi", "OpenBurnBarLibSignalFfi"]
    : ["SignalFfi"]

let libSignalClientLinkerSettings: [LinkerSetting] = [
    .linkedLibrary("stdc++", .when(platforms: [.linux]))
] + (hasOpenBurnBarSignalFfiXCFramework ? [] : [
    .unsafeFlags(["-L\(rustBuildDir)"])
])

let package = Package(
    name: "LibSignalClient",
    platforms: [
        .macOS(.v10_15), .iOS(.v13),
    ],
    products: [
        .library(
            name: "LibSignalClient",
            targets: ["LibSignalClient"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.3")
    ],
    targets: signalFfiBinaryTargets + [
        .systemLibrary(name: "SignalFfi"),
        .target(
            name: "LibSignalClient",
            dependencies: libSignalClientDependencies,
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")],
            linkerSettings: libSignalClientLinkerSettings
        ),
        .testTarget(
            name: "LibSignalClientTests",
            dependencies: ["LibSignalClient"],
            resources: [.process("Resources")],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")],
            linkerSettings: [.unsafeFlags(["-L\(rustBuildDir)"])]
        ),
    ]
)
