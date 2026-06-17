# Graph Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-primitives/swift-graph-primitives/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-primitives/swift-graph-primitives/actions/workflows/ci.yml)

`Graph.Sequential<Tag, Payload>` — an immutable directed graph with sequentially-allocated nodes. Payloads live in a dense array where each node's identity is its index, so node lookup is O(1) and traversal is cache-friendly. You build a graph with a `Builder` — allocate nodes with payloads, then `build()` — and the result is immutable.

On top of the graph sits a rich traversal and analysis surface: depth-first and breadth-first traversal, topological ordering, strongly-connected components, cycle detection, forward and backward reachability, and dead-node analysis. Node identity is phantom-typed by `Tag`, so a node from one graph cannot be used against another.

---

## Key Features

- **Dense, immutable, O(1) lookup** — payloads in a contiguous array indexed by node identity.
- **Builder construction** — `allocate` nodes, then `build()` an immutable graph.
- **Traversals** — depth-first, breadth-first, topological.
- **Analyses** — strongly-connected components, cycle detection, forward/backward reachability, dead nodes.
- **Tag-phantom-typed nodes** — node identities of different graphs are distinct types.

---

## Quick Start

```swift
import Graph_Primitives

enum Tag {}
var builder = Graph.Sequential<Tag, Int>.Builder()
let a = builder.allocate(10)
let b = builder.allocate(20)
let graph = builder.build()

// `graph` then exposes the traversal + analysis surface — depth/breadth-first,
// topological order, strongly-connected components, cycle detection, reachability,
// and dead-node analysis (each driven by an adjacency function over the payloads).
```

---

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-graph-primitives.git", branch: "main")
]
```

Add a product to your target:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Graph Primitives", package: "swift-graph-primitives")
    ]
)
```

The package is pre-1.0 — depend on `branch: "main"` until `0.1.0` is tagged. Requires Swift 6.3 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the corresponding Linux / Windows toolchain).

---

## Architecture

| Product | Contents | When to import |
|---------|----------|----------------|
| `Graph Primitives` | Umbrella — the graph, its `Builder`, and all traversals/analyses | Most consumers |
| `Graph Sequential Primitives` | `Graph.Sequential`, its `Builder`, and the operation namespaces | The graph type + construction only |
| `Graph Index` / `Adjacency` / `Traversal` / `Remappable Primitives` | Node identity / adjacency payload / traversal markers / node remapping | A single foundational sub-namespace |
| `Graph DFS` / `BFS` / `Topological Primitives` | Depth-first / breadth-first / topological traversal | A single traversal |
| `Graph SCC` / `Cycles` / `Reachable` / `Dead Primitives` | Strongly-connected components / cycles / reachability / dead-node analysis | A single analysis |

---

## Platform Support

| Platform         | CI  | Status       |
|------------------|-----|--------------|
| macOS 26         | Yes | Full support |
| Linux            | Yes | Full support |
| Windows          | Yes | Full support |
| iOS/tvOS/watchOS | —   | Supported    |
| Swift Embedded   | —   | Pending (nightly-toolchain follow-up) |

---

## Related Packages

- [`swift-array-primitives`](https://github.com/swift-primitives/swift-array-primitives) — the dense payload storage a graph is built over.
- [`swift-set-primitives`](https://github.com/swift-primitives/swift-set-primitives) — the ordered sets reachability and dead-node analyses return.
- [`swift-heap-primitives`](https://github.com/swift-primitives/swift-heap-primitives) — the priority queue behind priority-first traversals.

---

## Community

<!-- BEGIN: discussion -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
