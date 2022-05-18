// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let defines: [String]

#if MOZ_CHANNEL_DEBUG
defines = ["MOZ_CHANNEL_DEBUG"]
#elseif MOZ_CHANNEL_DEV
defines = ["MOZ_CHANNEL_DEV"]
#elseif MOZ_CHANNEL_BETA
defines = ["MOZ_CHANNEL_BETA"]
#elseif MOZ_CHANNEL_RELEASE
defines = ["MOZ_CHANNEL_RELEASE"]
#else
defines = ["MOZ_CHANNEL_RELEASE"]
#endif

let package = Package(
  name: "Brave",
  defaultLocalization: "en",
  platforms: [.iOS(.v14), .macOS(.v11)],
  products: [
    .library(name: "Shared", targets: ["Shared", "FSUtils"]),
    .library(name: "BraveCore", targets: ["BraveCore", "MaterialComponents"]),
    .library(name: "BraveShared", targets: ["BraveShared"]),
    .library(name: "BraveUI", targets: ["BraveUI"]),
    .library(name: "BraveWallet", targets: ["BraveWallet"]),
    .library(name: "Data", targets: ["Data"]),
    .library(name: "Storage", targets: ["Storage", "sqlcipher"]),
  ],
  dependencies: [
    .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.11"),
    .package(url: "https://github.com/SnapKit/SnapKit", from: "5.0.1"),
    .package(url: "https://github.com/DaveWoodCom/XCGLogger", from: "7.0.1"),
    .package(url: "https://github.com/cezheng/Fuzi", from: "3.1.3"),
    .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", from: "5.0.0"),
    .package(url: "https://github.com/airbnb/lottie-ios", from: "3.1.9"),
    .package(url: "https://github.com/jrendel/SwiftKeychainWrapper", from: "4.0.1"),
    .package(url: "https://github.com/rs/SDWebImage", from: "5.10.2"),
    .package(url: "https://github.com/nmdias/FeedKit", from: "9.1.2"),
    .package(url: "https://github.com/brave/PanModal", revision: "e4c07f8e6c5df937051fabc47e1e92901e1d068b"),
    .package(url: "https://github.com/apple/swift-collections", from: "0.0.2"),
    .package(url: "https://github.com/siteline/SwiftUI-Introspect", from: "0.1.3"),
    .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
    .package(url: "https://github.com/devxoul/Then", from: "2.7.0"),
    .package(url: "https://github.com/mkrd/Swift-BigInt", from: "2.0.0"),
    .package(url: "https://github.com/apple/swift-markdown", revision: "4f0c76fcd29fea648915f41e2aa896d47608087a"),
  ],
  targets: [
    .target(
      name: "Shared",
      dependencies: ["BraveCore", "FSUtils", "SDWebImage", "SwiftKeychainWrapper", "SwiftyJSON", "XCGLogger"],
      path: "Shared",
      exclude: ["FSUtils"],
      resources: [.copy("effective_tld_names.dat")],
      swiftSettings: defines.map { SwiftSetting.define($0) }
    ),
    .target(name: "FSUtils", path: "Shared/FSUtils", publicHeadersPath: "."),
    .target(
      name: "BraveShared",
      dependencies: ["SDWebImage", "Shared", "SnapKit", "XCGLogger"],
      path: "BraveShared"
    ),
    .target(
      name: "BraveUI",
      dependencies: [
        "BraveShared",
        .product(name: "Markdown", package: "swift-markdown"),
        "PanModal",
        "SDWebImage",
        "SnapKit",
        .product(name: "Introspect", package: "SwiftUI-Introspect"),
        "Then",
        "XCGLogger"
      ],
      path: "BraveUI"
    ),
    .binaryTarget(name: "BraveCore", path: "node_modules/brave-core-ios/BraveCore.xcframework"),
    .binaryTarget(name: "MaterialComponents", path: "node_modules/brave-core-ios/MaterialComponents.xcframework"),
    .binaryTarget(name: "sqlcipher", path: "ThirdParty/sqlcipher/sqlcipher.xcframework"),
    .binaryTarget(name: "GCDWebServers", path: "ThirdParty/GCDWebServers/GCDWebServers.xcframework"),
    .target(
      name: "Storage",
      dependencies: ["Shared", "sqlcipher", "SDWebImage", "XCGLogger"],
      path: "Storage",
      cSettings: [.define("SQLITE_HAS_CODEC")]
    ),
    .target(name: "Data", dependencies: ["BraveShared", "Storage"], path: "Data"),
    .target(
      name: "BraveWallet",
      dependencies: [
        "Data",
        "BraveCore",
        "BraveShared",
        "BraveUI",
        "PanModal",
        "SDWebImage",
        "SnapKit",
        "Then",
        "XCGLogger",
        .product(name: "BigNumber", package: "Swift-BigInt"),
        .product(name: "Algorithms", package: "swift-algorithms"),
      ],
      path: "BraveWallet"
    ),
    .target(name: "BraveSharedTestUtils", path: "BraveSharedTests", sources: ["BraveSharedTestUtils.swift"]),
    .testTarget(name: "SharedTests", dependencies: ["Shared"], path: "SharedTests"),
    .testTarget(
      name: "BraveSharedTests",
      dependencies: ["BraveShared", "BraveSharedTestUtils"],
      path: "BraveSharedTests",
      exclude: ["BraveSharedTestUtils.swift"],
      resources: [
        .copy("Certificates/root.cer"),
        .copy("Certificates/leaf.cer"),
        .copy("Certificates/intermediate.cer"),
        .copy("Certificates/self-signed.cer"),
        .copy("Certificates/untrusted-badssl.com-root.cer"),
        .copy("Certificates/expired.badssl.com/expired.badssl.com-intermediate-ca-1.cer"),
        .copy("Certificates/expired.badssl.com/expired.badssl.com-intermediate-ca-2.cer"),
        .copy("Certificates/expired.badssl.com/expired.badssl.com-leaf.cer"),
        .copy("Certificates/expired.badssl.com/expired.badssl.com-root-ca.cer"),
        .copy("Certificates/expired.badssl.com/self-signed.badssl.com.cer"),
        .copy("Certificates/expired.badssl.com/untrusted.badssl.com-leaf.cer"),
        .copy("Certificates/expired.badssl.com/untrusted.badssl.com-root.cer"),
        .copy("Certificates/certviewer/brave.com.cer"),
        .copy("Certificates/certviewer/github.com.cer"),
      ]
    ),
    .testTarget(name: "BraveWalletTests", dependencies: ["BraveWallet"], path: "BraveWalletTests"),
    .testTarget(name: "StorageTests", dependencies: ["Storage", "BraveSharedTestUtils"], path: "StorageTests", resources: [.copy("fixtures/v33.db"), .copy("testcert1.pem"), .copy("testcert2.pem")]),
    .testTarget(name: "DataTests", dependencies: ["Data"], path: "DataTests"),
    .testTarget(name: "SPMLibrariesTests", dependencies: ["GCDWebServers"], path: "SPMLibrariesTests")
  ]
)

