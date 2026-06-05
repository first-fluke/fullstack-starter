// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "firebase_crashlytics", path: "../.packages/firebase_crashlytics-5.2.3"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-4.10.0"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "firebase-crashlytics", package: "firebase_crashlytics"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
