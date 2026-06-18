// swift-tools-version:6.0

//
// Copyright 2020-2021 Signal Messenger, LLC.
// SPDX-License-Identifier: AGPL-3.0-only
//

import PackageDescription
import Foundation

let rustBuildDir = "../target/debug/"
let packageRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let hasOpenBurnBarSignalFfiIOSXCFramework = FileManager.default.fileExists(
    atPath: packageRoot
        .appendingPathComponent("../../OpenBurnBarSignalFfiIOS.xcframework")
        .standardizedFileURL
        .path
)
let hasOpenBurnBarSignalFfiMacXCFramework = FileManager.default.fileExists(
    atPath: packageRoot
        .appendingPathComponent("../../OpenBurnBarSignalFfiMac.xcframework")
        .standardizedFileURL
        .path
)
let hasLegacyOpenBurnBarSignalFfiXCFramework = FileManager.default.fileExists(
    atPath: packageRoot
        .appendingPathComponent("../../OpenBurnBarSignalFfi.xcframework")
        .standardizedFileURL
        .path
)

let signalFfiBinaryTargets: [Target] = {
    var targets: [Target] = []
    if hasOpenBurnBarSignalFfiIOSXCFramework {
        targets.append(.binaryTarget(
            name: "OpenBurnBarLibSignalFfiIOS",
            path: "../../OpenBurnBarSignalFfiIOS.xcframework"
        ))
    }
    if hasOpenBurnBarSignalFfiMacXCFramework {
        targets.append(.binaryTarget(
            name: "OpenBurnBarLibSignalFfiMac",
            path: "../../OpenBurnBarSignalFfiMac.xcframework"
        ))
    }
    if hasLegacyOpenBurnBarSignalFfiXCFramework && !hasOpenBurnBarSignalFfiMacXCFramework {
        targets.append(.binaryTarget(
            name: "OpenBurnBarLibSignalFfi",
            path: "../../OpenBurnBarSignalFfi.xcframework"
        ))
    }
    return targets
}()

let libSignalClientDependencies: [Target.Dependency] = {
    var dependencies: [Target.Dependency] = ["SignalFfi"]
    if hasOpenBurnBarSignalFfiIOSXCFramework {
        dependencies.append(.target(name: "OpenBurnBarLibSignalFfiIOS", condition: .when(platforms: [.iOS])))
    }
    if hasOpenBurnBarSignalFfiMacXCFramework {
        dependencies.append(.target(name: "OpenBurnBarLibSignalFfiMac", condition: .when(platforms: [.macOS])))
    }
    if hasLegacyOpenBurnBarSignalFfiXCFramework && !hasOpenBurnBarSignalFfiMacXCFramework {
        dependencies.append(.target(name: "OpenBurnBarLibSignalFfi", condition: .when(platforms: [.macOS])))
    }
    return dependencies
}()

let libSignalClientLinkerSettings: [LinkerSetting] = [
    .linkedLibrary("stdc++", .when(platforms: [.linux]))
] + (hasOpenBurnBarSignalFfiIOSXCFramework ? [] : [
    .unsafeFlags(["-L\(rustBuildDir)"], .when(platforms: [.iOS]))
]) + (hasOpenBurnBarSignalFfiMacXCFramework || hasLegacyOpenBurnBarSignalFfiXCFramework ? [] : [
    .unsafeFlags(["-L\(rustBuildDir)"], .when(platforms: [.macOS]))
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
