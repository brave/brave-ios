// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// News, Playlist (+JS), Onboarding, Browser (Favicons, Bookmarks, History, Passwords, Reader Mode, Settings, Sync),
// VPN, Rewards, Shields (Privacy, De-Amp, Downloaders, Content Blockers, ...), NTP, Networking,

let package = Package(
  name: "Brave",
  defaultLocalization: "en",
  platforms: [.iOS(.v14), .macOS(.v11)],
  products: [
    .library(name: "Brave", targets: ["Brave"]),
    .library(name: "GuardianVPN", targets: ["GuardianVPN"]),
    .library(name: "HTTPSE", targets: ["HTTPSE"]),
    .library(name: "Shared", targets: ["Shared", "FSUtils"]),
    .library(name: "BraveCore", targets: ["BraveCore", "MaterialComponents"]),
    .library(name: "BraveShared", targets: ["BraveShared"]),
    .library(name: "BraveUI", targets: ["BraveUI"]),
    .library(name: "BraveWallet", targets: ["BraveWallet"]),
    .library(name: "Data", targets: ["Data"]),
    .library(name: "Storage", targets: ["Storage", "sqlcipher"]),
    .library(name: "BrowserIntentsModels", targets: ["BrowserIntentsModels"]),
    .library(name: "BraveWidgetsModels", targets: ["BraveWidgetsModels"]),
    .library(name: "Strings", targets: ["Strings"]),
    .plugin(name: "IntentBuilderPlugin", targets: ["IntentBuilderPlugin"]),
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
    .package(name: "Static", path: "ThirdParty/Static"),
  ],
  targets: [
    .target(
      name: "Brave",
      dependencies: [
        "BraveShared",
        "Shared",
        "BraveWallet",
        "BraveCore",
        "BraveUI",
        "Data",
        "Storage",
        "GuardianVPN",
        "GCDWebServers",
        "HTTPSE",
        "Fuzi",
        "SnapKit",
        "Static",
        "ZIPFoundation",
        "SDWebImage",
        "FeedKit",
        "Then",
        "SwiftKeychainWrapper",
        "SwiftyJSON",
        "XCGLogger",
        "BrowserIntentsModels",
        "BraveWidgetsModels",
        .product(name: "Lottie", package: "lottie-ios"),
        .product(name: "Collections", package: "swift-collections"),
      ],
      path: "Client",
      exclude: [
        "Frontend/BraveVPN/GRDAPI",
        "WebFilters/ShieldStats/Httpse",
        "Frontend/UserContent/UserScripts/AllFrames",
        "Frontend/UserContent/UserScripts/MainFrame",
        "Frontend/UserContent/UserScripts/Sandboxed",
        "Assets/MainFrameAtDocumentEnd.js.LICENSE.txt",
        "Assets/MainFrameAtDocumentEndSandboxed.js.LICENSE.txt",
      ],
      resources: [
        .copy("Assets/About/Licenses.html"),
        .copy("Assets/AllFramesAtDocumentEnd.js"),
        .copy("Assets/AllFramesAtDocumentEndSandboxed.js"),
        .copy("Assets/AllFramesAtDocumentStart.js"),
        .copy("Assets/AllFramesAtDocumentStartSandboxed.js"),
        .copy("Assets/MainFrameAtDocumentEnd.js"),
        .copy("Assets/MainFrameAtDocumentEndSandboxed.js"),
        .copy("Assets/MainFrameAtDocumentStart.js"),
        .copy("Assets/MainFrameAtDocumentStartSandboxed.js"),
        .copy("Assets/SessionRestore.html"),
        .copy("Assets/SpotlightHelper.js"),
        .copy("Assets/top_sites.json"),
        .copy("Assets/Fonts/FiraSans-Bold.ttf"),
        .copy("Assets/Fonts/FiraSans-BoldItalic.ttf"),
        .copy("Assets/Fonts/FiraSans-Book.ttf"),
        .copy("Assets/Fonts/FiraSans-Italic.ttf"),
        .copy("Assets/Fonts/FiraSans-Light.ttf"),
        .copy("Assets/Fonts/FiraSans-Medium.ttf"),
        .copy("Assets/Fonts/FiraSans-Regular.ttf"),
        .copy("Assets/Fonts/FiraSans-SemiBold.ttf"),
        .copy("Assets/Fonts/FiraSans-UltraLight.ttf"),
        .copy("Assets/Fonts/NewYorkMedium-Bold.otf"),
        .copy("Assets/Fonts/NewYorkMedium-BoldItalic.otf"),
        .copy("Assets/Fonts/NewYorkMedium-Regular.otf"),
        .copy("Assets/Fonts/NewYorkMedium-RegularItalic.otf"),
        .copy("Assets/Interstitial Pages/Pages/CertificateError.html"),
        .copy("Assets/Interstitial Pages/Pages/GenericError.html"),
        .copy("Assets/Interstitial Pages/Pages/NetworkError.html"),
        .copy("Assets/Interstitial Pages/Images/Carret.png"),
        .copy("Assets/Interstitial Pages/Images/Clock.svg"),
        .copy("Assets/Interstitial Pages/Images/Cloud.svg"),
        .copy("Assets/Interstitial Pages/Images/DarkWarning.svg"),
        .copy("Assets/Interstitial Pages/Images/Generic.svg"),
        .copy("Assets/Interstitial Pages/Images/Globe.svg"),
        .copy("Assets/Interstitial Pages/Images/Info.svg"),
        .copy("Assets/Interstitial Pages/Images/Warning.svg"),
        .copy("Assets/Interstitial Pages/Styles/CertificateError.css"),
        .copy("Assets/Interstitial Pages/Styles/InterstitialStyles.css"),
        .copy("Assets/Interstitial Pages/Styles/NetworkError.css"),
        .copy("Assets/SearchPlugins"),
        .copy("Assets/TopSites"),
        .copy("Frontend/Reader/Reader.css"),
        .copy("Frontend/Reader/Reader.html"),
        .copy("Frontend/Reader/ReaderViewLoading.html"),
        .copy("MailSchemes.plist"),
        .copy("Frontend/BraveVPN/vpncheckmark.json"),
        .copy("Frontend/Browser/New Tab Page/Backgrounds/Assets/ntp-data.json"),
        .copy("Frontend/Browser/New Tab Page/Backgrounds/Assets/NTP_Images/alain_franchette_ocean.jpg"),
        .copy("Frontend/Browser/New Tab Page/Backgrounds/Assets/NTP_Images/boris_baldinger.jpg"),
        .copy("Frontend/Browser/New Tab Page/Backgrounds/Assets/NTP_Images/caline_beulin.jpg"),
        .copy("Frontend/Browser/New Tab Page/Backgrounds/Assets/NTP_Images/corwin-prescott_beach.jpg"),
        .copy("Frontend/Browser/New Tab Page/Backgrounds/Assets/NTP_Images/corwin-prescott_canyon.jpg"),
        .copy("Frontend/Browser/New Tab Page/Backgrounds/Assets/NTP_Images/corwin-prescott_crestone.jpg"),
        .copy("Frontend/Browser/New Tab Page/Backgrounds/Assets/NTP_Images/curt_stump_nature.jpg"),
        .copy("Frontend/Browser/New Tab Page/Backgrounds/Assets/NTP_Images/david_malenfant_mountains.jpg"),
        .copy("Frontend/Browser/New Tab Page/Backgrounds/Assets/NTP_Images/dylan-malval_sea.jpg"),
        .copy("Frontend/Browser/New Tab Page/Backgrounds/Assets/NTP_Images/geran_de_klerk_forest.jpg"),
        .copy("Frontend/Browser/New Tab Page/Backgrounds/Assets/NTP_Images/joshn_larson_desert.jpg"),
        .copy("Frontend/Browser/New Tab Page/Backgrounds/Assets/NTP_Images/priyanuch_konkaew.jpg"),
        .copy("Frontend/Browser/New Tab Page/Backgrounds/Assets/NTP_Images/spencer-moore_desert.jpg"),
        .copy("Frontend/Browser/New Tab Page/Backgrounds/Assets/NTP_Images/spencer-moore_fern.jpg"),
        .copy("Frontend/Browser/New Tab Page/Backgrounds/Assets/NTP_Images/spencer-moore_ocean.jpg"),
        .copy("Frontend/Browser/Onboarding/onboarding-ads.json"),
        .copy("Frontend/Browser/Onboarding/onboarding-rewards.json"),
        .copy("Frontend/Browser/Onboarding/onboarding-shields.json"),
        .copy("Frontend/Browser/Onboarding/Welcome/disconnect-entitylist.json"),
        .copy("Frontend/Browser/BrowserViewController/ProductNotifications/blocking-summary.json"),
        .copy("Frontend/Brave Today/Lottie Assets/brave-today-welcome-graphic.json"),
        .copy("Frontend/Sync/WebFilter/Bookmarks/Bookmarks.html"),
        .copy("Frontend/UserContent/UserScripts/ArchiveIsCompat.js"),
        .copy("Frontend/UserContent/UserScripts/BraveSearchHelper.js"),
        .copy("Frontend/UserContent/UserScripts/BraveTalkHelper.js"),
        .copy("Frontend/UserContent/UserScripts/CookieControl.js"),
        .copy("Frontend/UserContent/UserScripts/FarblingProtection.js"),
        .copy("Frontend/UserContent/UserScripts/FullscreenHelper.js"),
        .copy("Frontend/UserContent/UserScripts/MediaBackgrounding.js"),
        .copy("Frontend/UserContent/UserScripts/nacl.min.js"),
        .copy("Frontend/UserContent/UserScripts/PaymentRequest.js"),
        .copy("Frontend/UserContent/UserScripts/Playlist.js"),
        .copy("Frontend/UserContent/UserScripts/PlaylistDetector.js"),
        .copy("Frontend/UserContent/UserScripts/PlaylistSwizzler.js"),
        .copy("Frontend/UserContent/UserScripts/ReadyState.js"),
        .copy("Frontend/UserContent/UserScripts/WalletEthereumProvider.js"),
        .copy("Frontend/UserContent/UserScripts/YoutubeAdblock.js"),
        .copy("Frontend/UserContent/UserScripts/DeAMP.js"),
        .copy("WebFilters/ContentBlocker/build-disconnect.py"),
        .copy("WebFilters/ContentBlocker/Lists/block-ads.json"),
        .copy("WebFilters/ContentBlocker/Lists/block-cookies.json"),
        .copy("WebFilters/ContentBlocker/Lists/block-images.json"),
        .copy("WebFilters/ContentBlocker/Lists/block-trackers.json"),
        .copy("WebFilters/ContentBlocker/Lists/upgrade-http.json"),
        .copy("WebFilters/ShieldStats/Adblock/Resources/ABPFilterParserData.dat"),
        .copy("WebFilters/SafeBrowsing/SafeBrowsingError.html"),
        .copy("WebFilters/ShieldStats/Httpse/httpse.leveldb.tgz"),
      ]
    ),
    .target(name: "GuardianVPN", path: "Client/Frontend/BraveVPN/GRDAPI", publicHeadersPath: "."),
    .target(
      name: "HTTPSE",
      path: "Client/WebFilters/ShieldStats/Httpse",
      cxxSettings: [
        .headerSearchPath("include"),
        .headerSearchPath("ThirdParty/**"),
        .headerSearchPath("Cpp")
      ]
    ),
    .target(
      name: "Shared",
      dependencies: [
        "BraveCore",
        "FSUtils",
        "Strings",
        "SDWebImage",
        "SwiftKeychainWrapper",
        "SwiftyJSON",
        "XCGLogger",
      ],
      path: "Shared",
      exclude: ["FSUtils"],
      resources: [.copy("effective_tld_names.dat")],
      swiftSettings: [.define("MOZ_CHANNEL_RELEASE")]
    ),
    .target(name: "FSUtils", path: "Shared/FSUtils", publicHeadersPath: "."),
    .target(
      name: "BraveShared",
      dependencies: ["SDWebImage", "Shared", "Strings", "SnapKit", "XCGLogger"],
      path: "BraveShared",
      resources: [
        .copy("Certificates/AmazonRootCA1.cer"),
        .copy("Certificates/AmazonRootCA2.cer"),
        .copy("Certificates/AmazonRootCA3.cer"),
        .copy("Certificates/AmazonRootCA4.cer"),
        .copy("Certificates/GlobalSignRootCA_E46.cer"),
        .copy("Certificates/GlobalSignRootCA_R1.cer"),
        .copy("Certificates/GlobalSignRootCA_R3.cer"),
        .copy("Certificates/GlobalSignRootCA_R46.cer"),
        .copy("Certificates/GlobalSignRootCA_R5.cer"),
        .copy("Certificates/GlobalSignRootCA_R6.cer"),
        .copy("Certificates/ISRGRootCA_X1.cer"),
        .copy("Certificates/ISRGRootCA_X2.cer"),
        .copy("Certificates/SFSRootCAG2.cer"),
      ]
    ),
    .target(
      name: "BraveUI",
      dependencies: [
        "BraveShared",
        "Strings",
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
    .target(name: "Data", dependencies: ["BraveShared", "Storage", "Strings"], path: "Data"),
    .target(
      name: "BraveWallet",
      dependencies: [
        "Data",
        "BraveCore",
        "BraveShared",
        "BraveUI",
        "Strings",
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
    .target(
      name: "BrowserIntentsModels",
      path: "BrowserIntentsModels",
      sources: ["BrowserIntents.intentdefinition", "CustomIntentHandler.swift"],
      plugins: ["IntentBuilderPlugin"]
    ),
    .target(
      name: "BraveWidgetsModels",
      path: "BraveWidgetsModels",
      sources: ["BraveWidgets.intentdefinition", "Empty.swift"],
      plugins: ["IntentBuilderPlugin"]
    ),
    .target(name: "BraveSharedTestUtils", path: "BraveSharedTestUtils"),
    .target(name: "DataTestsUtils", dependencies: ["Data", "BraveShared"], path: "DataTestsUtils"),
    .testTarget(name: "SharedTests", dependencies: ["Shared"], path: "SharedTests"),
    .testTarget(
      name: "BraveSharedTests",
      dependencies: ["BraveShared", "BraveSharedTestUtils"],
      path: "BraveSharedTests",
      exclude: [ "Certificates/self-signed.conf" ],
      resources: [
        .copy("Certificates/root.cer"),
        .copy("Certificates/leaf.cer"),
        .copy("Certificates/intermediate.cer"),
        .copy("Certificates/self-signed.cer"),
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
    .testTarget(name: "BraveWalletTests", dependencies: ["BraveWallet", "DataTestsUtils"], path: "BraveWalletTests"),
    .testTarget(name: "StorageTests", dependencies: ["Storage", "BraveSharedTestUtils"], path: "StorageTests", resources: [.copy("fixtures/v33.db"), .copy("testcert1.pem"), .copy("testcert2.pem")]),
    .testTarget(name: "DataTests", dependencies: ["Data", "DataTestsUtils"], path: "DataTests"),
    .testTarget(name: "SPMLibrariesTests", dependencies: ["GCDWebServers"], path: "SPMLibrariesTests"),
    .testTarget(
      name: "ClientTests",
      dependencies: ["Brave", "BraveSharedTestUtils"],
      path: "ClientTests",
      resources: [
        .copy("Resources/debouncing.json"),
        .copy("Resources/google-search-plugin.xml"),
        .copy("Resources/duckduckgo-search-plugin.xml"),
        .copy("opml-test-files/subscriptionList.opml"),
        .copy("opml-test-files/states.opml"),
        .copy("blocking-summary-test.json"),
      ]
    ),
    .target(name: "Strings", path: "App/l10n", exclude: ["tools", "Resources/Info.plist"]),
    .plugin(name: "IntentBuilderPlugin", capability: .buildTool())
  ],
  cxxLanguageStandard: .cxx17
)
