// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-graph-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "Graph Primitives",
            targets: ["Graph Primitives"]
        ),
        .library(
            name: "Graph Primitives Test Support",
            targets: ["Graph Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-identity-primitives"),
        .package(path: "../swift-bit-primitives"),
        .package(path: "../swift-stack-primitives"),
        .package(path: "../swift-set-primitives"),
        .package(path: "../swift-heap-primitives"),
        .package(path: "../swift-index-primitives"),
        .package(path: "../swift-input-primitives"),
        .package(path: "../swift-array-primitives"),
        .package(path: "../swift-collection-primitives"),
        .package(path: "../swift-queue-primitives"),
        .package(path: "../swift-dictionary-primitives"),
        .package(path: "../swift-bit-vector-primitives"),
        .package(path: "../swift-sequence-primitives"),
    ],
    targets: [
        .target(
            name: "Graph Primitives",
            dependencies: [
                .product(name: "Identity Primitives", package: "swift-identity-primitives"),
                .product(name: "Bit Primitives", package: "swift-bit-primitives"),
                .product(name: "Stack Primitives", package: "swift-stack-primitives"),
                .product(name: "Set Primitives", package: "swift-set-primitives"),
                .product(name: "Heap Primitives", package: "swift-heap-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Input Primitives", package: "swift-input-primitives"),
                .product(name: "Array Primitives", package: "swift-array-primitives"),
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
                .product(name: "Queue Primitives", package: "swift-queue-primitives"),
                .product(name: "Dictionary Primitives", package: "swift-dictionary-primitives"),
                .product(name: "Bit Vector Primitives", package: "swift-bit-vector-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
            ]
        ),
        .target(
            name: "Graph Primitives Test Support",
            dependencies: [
                "Graph Primitives",
                .product(name: "Set Primitives Test Support", package: "swift-set-primitives"),
                .product(name: "Array Primitives Test Support", package: "swift-array-primitives"),
                .product(name: "Bit Vector Primitives Test Support", package: "swift-bit-vector-primitives"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Graph Primitives Tests",
            dependencies: [
                "Graph Primitives",
                "Graph Primitives Test Support",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableExperimentalFeature("SuppressedAssociatedTypesWithDefaults"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
