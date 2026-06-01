// swift-tools-version: 6.3.1

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
        // MARK: - Namespace
        .library(
            name: "Graph Primitive",
            targets: ["Graph Primitive"]
        ),
        .library(
            name: "Graph Primitives",
            targets: ["Graph Primitives"]
        ),
        .library(
            name: "Graph Primitives Core",
            targets: ["Graph Primitives Core"]
        ),
        .library(
            name: "Graph DFS Primitives",
            targets: ["Graph DFS Primitives"]
        ),
        .library(
            name: "Graph BFS Primitives",
            targets: ["Graph BFS Primitives"]
        ),
        .library(
            name: "Graph Topological Primitives",
            targets: ["Graph Topological Primitives"]
        ),
        .library(
            name: "Graph Reachable Primitives",
            targets: ["Graph Reachable Primitives"]
        ),
        .library(
            name: "Graph Dead Primitives",
            targets: ["Graph Dead Primitives"]
        ),
        .library(
            name: "Graph SCC Primitives",
            targets: ["Graph SCC Primitives"]
        ),
        .library(
            name: "Graph Cycles Primitives",
            targets: ["Graph Cycles Primitives"]
        ),
        .library(
            name: "Graph Transitive Closure Primitives",
            targets: ["Graph Transitive Closure Primitives"]
        ),
        .library(
            name: "Graph Path Exists Primitives",
            targets: ["Graph Path Exists Primitives"]
        ),
        .library(
            name: "Graph Shortest Path Primitives",
            targets: ["Graph Shortest Path Primitives"]
        ),
        .library(
            name: "Graph Weighted Path Primitives",
            targets: ["Graph Weighted Path Primitives"]
        ),
        .library(
            name: "Graph Payload Map Primitives",
            targets: ["Graph Payload Map Primitives"]
        ),
        .library(
            name: "Graph Subgraph Primitives",
            targets: ["Graph Subgraph Primitives"]
        ),
        .library(
            name: "Graph Reverse Primitives",
            targets: ["Graph Reverse Primitives"]
        ),
        .library(
            name: "Graph Backward Reachable Primitives",
            targets: ["Graph Backward Reachable Primitives"]
        ),
        .library(
            name: "Graph Primitives Test Support",
            targets: ["Graph Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-tagged-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-tagged-collection-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-bit-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-stack-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-set-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-set-ordered-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-heap-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-array-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-queue-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-bit-vector-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-sequence-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-iterator-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-vector-primitives.git", branch: "main"),
    ],
    targets: [
        // MARK: - Namespace

        .target(
            name: "Graph Primitive",
            dependencies: []
        ),

        // MARK: - Core

        .target(
            name: "Graph Primitives Core",
            dependencies: [
                "Graph Primitive",
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
                .product(name: "Tagged Collection Primitives", package: "swift-tagged-collection-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Array Primitives", package: "swift-array-primitives"),
                .product(name: "Vector Primitives", package: "swift-vector-primitives"),
            ]
        ),

        // MARK: - Traversal

        .target(
            name: "Graph DFS Primitives",
            dependencies: [
                "Graph Primitives Core",
                .product(name: "Stack Primitives", package: "swift-stack-primitives"),
                .product(name: "Bit Vector Primitives", package: "swift-bit-vector-primitives"),
                .product(name: "Iterator Chunk Primitives", package: "swift-iterator-primitives"),
                .product(name: "Tagged Collection Primitives", package: "swift-tagged-collection-primitives"),
            ]
        ),
        .target(
            name: "Graph BFS Primitives",
            dependencies: [
                "Graph Primitives Core",
                .product(name: "Queue Primitives", package: "swift-queue-primitives"),
                .product(name: "Bit Vector Primitives", package: "swift-bit-vector-primitives"),
                .product(name: "Iterator Chunk Primitives", package: "swift-iterator-primitives"),
                .product(name: "Tagged Collection Primitives", package: "swift-tagged-collection-primitives"),
            ]
        ),
        .target(
            name: "Graph Topological Primitives",
            dependencies: [
                "Graph Primitives Core",
                .product(name: "Stack Primitives", package: "swift-stack-primitives"),
                .product(name: "Bit Vector Primitives", package: "swift-bit-vector-primitives"),
                .product(name: "Tagged Collection Primitives", package: "swift-tagged-collection-primitives"),
            ]
        ),

        // MARK: - Analysis

        .target(
            name: "Graph Reachable Primitives",
            dependencies: [
                "Graph Primitives Core",
                .product(name: "Stack Primitives", package: "swift-stack-primitives"),
                .product(name: "Bit Vector Primitives", package: "swift-bit-vector-primitives"),
                .product(name: "Set Ordered Primitives", package: "swift-set-ordered-primitives"),
                .product(name: "Set Primitives", package: "swift-set-primitives"),
                .product(name: "Tagged Collection Primitives", package: "swift-tagged-collection-primitives"),
            ]
        ),
        .target(
            name: "Graph Dead Primitives",
            dependencies: [
                "Graph Primitives Core",
                "Graph Reachable Primitives",
                .product(name: "Stack Primitives", package: "swift-stack-primitives"),
                .product(name: "Bit Vector Primitives", package: "swift-bit-vector-primitives"),
                .product(name: "Set Ordered Primitives", package: "swift-set-ordered-primitives"),
                .product(name: "Set Primitives", package: "swift-set-primitives"),
                .product(name: "Tagged Collection Primitives", package: "swift-tagged-collection-primitives"),
            ]
        ),
        .target(
            name: "Graph SCC Primitives",
            dependencies: [
                "Graph Primitives Core",
                .product(name: "Stack Primitives", package: "swift-stack-primitives"),
                .product(name: "Bit Vector Primitives", package: "swift-bit-vector-primitives"),
                .product(name: "Tagged Collection Primitives", package: "swift-tagged-collection-primitives"),
            ]
        ),
        .target(
            name: "Graph Cycles Primitives",
            dependencies: [
                "Graph Primitives Core",
                "Graph Topological Primitives",
            ]
        ),
        .target(
            name: "Graph Transitive Closure Primitives",
            dependencies: [
                "Graph Primitives Core",
                .product(name: "Stack Primitives", package: "swift-stack-primitives"),
                .product(name: "Bit Vector Primitives", package: "swift-bit-vector-primitives"),
                .product(name: "Tagged Collection Primitives", package: "swift-tagged-collection-primitives"),
            ]
        ),

        // MARK: - Path

        .target(
            name: "Graph Path Exists Primitives",
            dependencies: [
                "Graph Primitives Core",
                .product(name: "Queue Primitives", package: "swift-queue-primitives"),
                .product(name: "Bit Vector Primitives", package: "swift-bit-vector-primitives"),
                .product(name: "Tagged Collection Primitives", package: "swift-tagged-collection-primitives"),
            ]
        ),
        .target(
            name: "Graph Shortest Path Primitives",
            dependencies: [
                "Graph Primitives Core",
                .product(name: "Queue Primitives", package: "swift-queue-primitives"),
                .product(name: "Bit Vector Primitives", package: "swift-bit-vector-primitives"),
                .product(name: "Tagged Collection Primitives", package: "swift-tagged-collection-primitives"),
            ]
        ),
        .target(
            name: "Graph Weighted Path Primitives",
            dependencies: [
                "Graph Primitives Core",
                .product(name: "Heap Primitives", package: "swift-heap-primitives"),
                .product(name: "Bit Vector Primitives", package: "swift-bit-vector-primitives"),
                .product(name: "Tagged Collection Primitives", package: "swift-tagged-collection-primitives"),
            ]
        ),

        // MARK: - Transform

        .target(
            name: "Graph Payload Map Primitives",
            dependencies: [
                "Graph Primitives Core",
            ]
        ),
        .target(
            name: "Graph Subgraph Primitives",
            dependencies: [
                "Graph Primitives Core",
                .product(name: "Set Ordered Primitives", package: "swift-set-ordered-primitives"),
                .product(name: "Set Primitives", package: "swift-set-primitives"),
                .product(name: "Tagged Collection Primitives", package: "swift-tagged-collection-primitives"),
            ]
        ),

        // MARK: - Reverse

        .target(
            name: "Graph Reverse Primitives",
            dependencies: [
                "Graph Primitives Core",
                .product(name: "Tagged Collection Primitives", package: "swift-tagged-collection-primitives"),
            ]
        ),
        .target(
            name: "Graph Backward Reachable Primitives",
            dependencies: [
                "Graph Primitives Core",
                "Graph Reverse Primitives",
                .product(name: "Stack Primitives", package: "swift-stack-primitives"),
                .product(name: "Bit Vector Primitives", package: "swift-bit-vector-primitives"),
                .product(name: "Set Ordered Primitives", package: "swift-set-ordered-primitives"),
                .product(name: "Set Primitives", package: "swift-set-primitives"),
                .product(name: "Tagged Collection Primitives", package: "swift-tagged-collection-primitives"),
            ]
        ),

        // MARK: - Umbrella

        .target(
            name: "Graph Primitives",
            dependencies: [
                "Graph Primitive",
                "Graph Primitives Core",
                "Graph DFS Primitives",
                "Graph BFS Primitives",
                "Graph Topological Primitives",
                "Graph Reachable Primitives",
                "Graph Dead Primitives",
                "Graph SCC Primitives",
                "Graph Cycles Primitives",
                "Graph Transitive Closure Primitives",
                "Graph Path Exists Primitives",
                "Graph Shortest Path Primitives",
                "Graph Weighted Path Primitives",
                "Graph Payload Map Primitives",
                "Graph Subgraph Primitives",
                "Graph Reverse Primitives",
                "Graph Backward Reachable Primitives",
            ]
        ),

        // MARK: - Test Support

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
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
