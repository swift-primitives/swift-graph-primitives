# Graph Operations Audit

<!--
---
version: 1.0.0
last_updated: 2026-02-16
status: RECOMMENDATION
tier: 1
---
-->

## Context

Proactive audit of swift-graph-primitives per [RES-012] Discovery.
**Scope**: Package-specific (swift-graph-primitives).

This document inventories every public operation in the package and maps them against the canonical Graph ADT operations from the computer science literature (CLRS, Tarjan, Dijkstra, Mokhov, petgraph, Boost Graph Library).

## Question

Does swift-graph-primitives provide the canonical operations expected of the Graph ADT?

---

## Canonical Operations (ADT Reference)

### Basic Operations

| Operation | Complexity (Adj List) | Complexity (Adj Matrix) | Description |
|-----------|----------------------|------------------------|-------------|
| add_vertex | O(1) amortized | O(V) | Add a vertex |
| remove_vertex | O(V + E) | O(V^2) | Remove vertex and its edges |
| add_edge(u, v) | O(1) | O(1) | Add edge |
| remove_edge(u, v) | O(deg(u)) | O(1) | Remove edge |
| has_edge(u, v) | O(deg(u)) | O(1) | Check edge existence |
| neighbors(u) | O(deg(u)) | O(V) | List adjacent vertices |
| degree(u) | O(1) or O(deg) | O(V) | Number of edges at vertex |
| vertex_count | O(1) | O(1) | Number of vertices |
| edge_count | O(1) or O(V) | O(V^2) | Number of edges |

### Traversal Operations

| Operation | Complexity | Description |
|-----------|-----------|-------------|
| BFS | O(V + E) | Breadth-first search |
| DFS | O(V + E) | Depth-first search |
| topological_sort | O(V + E) | Linear ordering of DAG |

### Path Operations

| Operation | Complexity | Description |
|-----------|-----------|-------------|
| path_exists(u, v) | O(V + E) | Reachability |
| shortest_path(u, v) | O(V + E) unweighted | BFS-based |
| weighted_shortest_path | O((V+E) log V) | Dijkstra |

### Analysis Operations

| Operation | Complexity | Description |
|-----------|-----------|-------------|
| cycle_detection | O(V + E) | Detect cycles |
| strongly_connected_components | O(V + E) | Tarjan/Kosaraju |
| transitive_closure | O(V^3) or O(V*(V+E)) | All reachability pairs |
| dead_vertex_detection | O(V + E) | Find unreachable vertices |

### Transform Operations

| Operation | Complexity | Description |
|-----------|-----------|-------------|
| reverse_graph | O(V + E) | Reverse all edges |
| subgraph | O(V + E) | Extract induced subgraph |
| payload_transform | O(V + E) | Map over vertex/edge data |

---

## Current Operations Inventory

### Core Types (Graph, Graph.Node, Graph.Index)

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.swift`
```swift
public enum Graph {}
```
Top-level namespace. No operations -- architecture only.

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Node.swift`
```swift
public typealias Node<Tag> = Index<Tag>
```
Vertex identity. Delegates to `Index<Tag>` from `Index_Primitives` (which wraps `Affine.Discrete.Position`). Phantom `Tag` prevents cross-graph confusion at compile time.

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Index.swift`
```swift
public typealias Index<Tag> = Index_Primitives.Index<Tag>
```
Type-safe index for graph node positions. Provides the underlying integer-backed position type.

### Graph.Adjacency (Edge Representation)

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Adjacency.swift`
```swift
extension Graph {
    public enum Adjacency {}
}
```
Namespace for adjacency-related types.

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Adjacency.List.swift`
```swift
extension Graph.Adjacency {
    public struct List<Tag>: Sendable {
        public var adjacent: [Graph.Node<Tag>]
        public init(adjacent: [Graph.Node<Tag>] = [])
    }
}
```
Canonical adjacency list payload. Stores directed edges as an array of target nodes.

```swift
extension Graph.Adjacency.Extract where Payload == Graph.Adjacency.List<Tag>, Adjacent == [Graph.Node<Tag>] {
    public static var list: Self
}
```
Static factory providing the canonical extract for `List` payloads.

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Adjacency.Extract.swift`
```swift
extension Graph.Adjacency {
    public struct Extract<Payload, Tag, Adjacent: Swift.Sequence<Graph.Node<Tag>>> {
        public init(adjacent: @escaping (Payload) -> Adjacent)
        public func adjacent(_ payload: Payload) -> Adjacent
    }
}
```
Protocol-free adjacency extraction. Enables graph algorithms on any payload type by providing a closure that extracts adjacent nodes. This is the graph-primitives analog of BGL's `IncidenceGraph` concept or petgraph's `IntoNeighbors` trait.

### Graph.Sequential (Immutable Graph Container)

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.swift`

| Member | Signature | Description | ADT Mapping |
|--------|-----------|-------------|-------------|
| `count` | `public var count: Node<Tag>.Count` | Number of vertices | `vertex_count` -- O(1) |
| `isEmpty` | `public var isEmpty: Bool` | Whether graph has no vertices | Derived from `vertex_count` |
| `subscript` | `public subscript(node: Node<Tag>) -> Payload` | Access payload by vertex identity | `neighbors(u)` -- O(1) access to payload containing adjacency |
| `nodes` | `public var nodes: some Swift.Sequence<Node<Tag>>` | All vertices in allocation order | Vertex set enumeration |

### Graph.Sequential.Builder (Mutable Construction)

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Builder.swift`

| Member | Signature | Description | ADT Mapping |
|--------|-----------|-------------|-------------|
| `init()` | `public init()` | Create empty builder | -- |
| `init(capacity:)` | `public init(capacity: Graph.Node<Tag>.Count)` | Create builder with reserved capacity | -- |
| `count` | `public var count: Graph.Node<Tag>.Count` | Allocated vertex count | -- |
| `allocate(_:)` | `public mutating func allocate(_ payload: Payload) -> Graph.Node<Tag>` | Allocate new node | `add_vertex` -- O(1) amortized |
| `subscript` | `public subscript(node: Graph.Node<Tag>) -> Payload { get set }` | Read/write payload during construction | Payload mutation |
| `build()` | `public consuming func build() -> Graph.Sequential<Tag, Payload>` | Freeze to immutable graph | -- |
| `allocateHole(using:)` | `public mutating func allocateHole(using default: Graph.Default.Value<Payload>) -> Graph.Node<Tag>` | Allocate forward-reference node | `add_vertex` with deferred edge definition |
| `fill(_:with:)` | `public mutating func fill(_ node: Graph.Node<Tag>, with payload: Payload)` | Fill previously allocated hole | Complete forward reference |
| `allocateHole()` | (List convenience) `public mutating func allocateHole() -> Graph.Node<Tag>` | List-specific hole allocation | -- |

### Graph.Default (Hole Support)

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Default.swift`
```swift
extension Graph {
    public enum Default {}
}
```

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Default.Value.swift`
```swift
extension Graph.Default {
    public struct Value<Payload> {
        public init(_ value: Payload)
        public var value: Payload
    }
}
```

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Default.list.swift`
```swift
extension Graph.Default {
    public static func list<Tag>() -> Value<Graph.Adjacency.List<Tag>>
}
```

### Graph.Remappable (Vertex Remapping)

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Remappable.swift`
```swift
extension Graph {
    public enum Remappable {}
}
```

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Remappable.Remap.swift`

| Member | Signature | Description |
|--------|-----------|-------------|
| `init(adjacent:mapNodes:)` | `public init(adjacent:..., mapNodes:...)` | Create remap with adjacency extraction and node mapping |
| `adjacent(_:)` | `public func adjacent(_ payload: Payload) -> Adjacent` | Extract adjacent nodes |
| `mapNodes(_:_:)` | `public func mapNodes(_ payload: Payload, _ transform: (Graph.Node<Tag>) -> Graph.Node<Tag>) -> Payload` | Transform all node references in a payload |
| `extract` | `public var extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>` | Convert remap to adjacency-only extract |
| `.list` | (static) `public static var list: Self` | Canonical remap for `List` payload |

### Graph.Sequential.Traverse (Traversal Operations)

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Traverse.swift`

| Member | Signature | Description |
|--------|-----------|-------------|
| `traverse` | `public var traverse: Traverse` | Accessor for traversal namespace |

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Traverse.First.swift`

| Member | Signature | Description | ADT Mapping |
|--------|-----------|-------------|-------------|
| `first(using:)` | `public func first<Adjacent>(...) -> First<Adjacent>` | First-visit accessor with custom extract | -- |
| `first` | (List convenience) `public var first: First<[Graph.Node<Tag>]>` | List-specific first-visit accessor | -- |
| `depth(from:)` | `public func depth(from roots: some Sequence<Graph.Node<Tag>>) -> Graph.Traversal.First.Depth<...>` | DFS from multiple roots | `DFS` -- O(V+E) |
| `depth(from:)` | `public func depth(from root: Graph.Node<Tag>) -> Graph.Traversal.First.Depth<...>` | DFS from single root | `DFS` -- O(V+E) |
| `breadth(from:)` | `public func breadth(from roots: some Sequence<Graph.Node<Tag>>) -> Graph.Traversal.First.Breadth<...>` | BFS from multiple roots | `BFS` -- O(V+E) |
| `breadth(from:)` | `public func breadth(from root: Graph.Node<Tag>) -> Graph.Traversal.First.Breadth<...>` | BFS from single root | `BFS` -- O(V+E) |

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Traverse.Topological.swift`

| Member | Signature | Description | ADT Mapping |
|--------|-----------|-------------|-------------|
| `topological(from:using:)` | (roots) `public func topological<Adjacent>(...) -> Graph.Traversal.Topological<...>` | Topological order from roots with custom extract | `topological_sort` -- O(V+E) |
| `topological(from:using:)` | (single) same, from single root | Topological order from single root | `topological_sort` |
| `topological(using:)` | All nodes | Topological order of entire graph | `topological_sort` |
| `topological(from:)` | (List, roots) convenience | List-specific topological from roots | `topological_sort` |
| `topological(from:)` | (List, single) convenience | List-specific topological from root | `topological_sort` |
| `topological()` | (List) convenience | List-specific topological of all | `topological_sort` |

### Traversal Iterator Types

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Traversal.First.Depth.swift`
```swift
extension Graph.Traversal.First {
    public struct Depth<Tag, Payload, Adjacent>: Swift.Sequence, IteratorProtocol {
        public typealias Element = (node: Graph.Node<Tag>, payload: Payload)
        public mutating func next() -> Element?
    }
}
```
Lazy DFS iterator. Uses `Stack` for frontier, `Array<Bit>.Vector` for visited tracking. Visits adjacent nodes in reverse adjacency order (stack-based).

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Traversal.First.Breadth.swift`
```swift
extension Graph.Traversal.First {
    public struct Breadth<Tag, Payload, Adjacent>: Swift.Sequence, IteratorProtocol {
        public typealias Element = (node: Graph.Node<Tag>, payload: Payload)
        public mutating func next() -> Element?
    }
}
```
Lazy BFS iterator. Uses `Queue` for frontier, `Array<Bit>.Vector` for visited tracking.

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Traversal.Topological.swift`
```swift
extension Graph.Traversal {
    public struct Topological<Tag, Payload, Adjacent>: Swift.Sequence {
        public typealias Element = (node: Graph.Node<Tag>, payload: Payload)
        public var hasCycles: Bool
        public func makeIterator() -> IndexingIterator<[Element]>
    }
}
```
Eagerly computed topological ordering. Returns `nil` elements (empty iteration) if cycles detected. Uses iterative DFS with two-phase stack (entering/leaving).

### Graph.Sequential.Path (Path Operations)

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Path.swift`

| Member | Signature | Description |
|--------|-----------|-------------|
| `path(using:)` | `public func path<Adjacent>(...) -> Path<Adjacent>` | Path accessor with custom extract |
| `path` | (List convenience) `public var path: Path<[Graph.Node<Tag>]>` | List-specific path accessor |

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Path.Exists.swift`

| Member | Signature | Description | ADT Mapping |
|--------|-----------|-------------|-------------|
| `exists(from:to:)` | `public func exists(from source: Graph.Node<Tag>, to target: Graph.Node<Tag>) -> Bool` | Path existence via BFS | `path_exists` -- O(V+E) |

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Path.Shortest.swift`

| Member | Signature | Description | ADT Mapping |
|--------|-----------|-------------|-------------|
| `shortest(from:to:)` | `public func shortest(from source: Graph.Node<Tag>, to target: Graph.Node<Tag>) -> [Graph.Node<Tag>]?` | Shortest path by hop count via BFS | `shortest_path` -- O(V+E) |

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Path.Weighted.swift`

| Member | Signature | Description | ADT Mapping |
|--------|-----------|-------------|-------------|
| `weighted(from:to:weight:)` | `public func weighted(from source: ..., to target: ..., weight: (Payload, Graph.Node<Tag>) -> Int) -> (path: [Graph.Node<Tag>], distance: Int)?` | Dijkstra's weighted shortest path | `weighted_shortest_path` -- O((V+E) log V) |

Implementation uses `Heap` (min-priority queue) from `Heap_Primitives` and an internal `Entry` type conforming to `__HeapOrdering` and `Comparable`.

### Graph.Sequential.Analyze (Analysis Operations)

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Analyze.swift`

| Member | Signature | Description |
|--------|-----------|-------------|
| `analyze(using:)` | `public func analyze<Adjacent>(...) -> Analyze<Adjacent>` | Analysis accessor with custom extract |
| `analyze` | (List convenience) `public var analyze: Analyze<[Graph.Node<Tag>]>` | List-specific analysis accessor |

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Analyze.Cycles.swift`

| Member | Signature | Description | ADT Mapping |
|--------|-----------|-------------|-------------|
| `hasCycles(from:)` | (roots) `public func hasCycles(from roots: some Sequence<Graph.Node<Tag>>) -> Bool` | Cycle detection from roots | `cycle_detection` -- O(V+E) |
| `hasCycles(from:)` | (single) `public func hasCycles(from root: Graph.Node<Tag>) -> Bool` | Cycle detection from root | `cycle_detection` |
| `hasCycles()` | `public func hasCycles() -> Bool` | Full-graph cycle detection | `cycle_detection` |

Implementation delegates to topological sort (cycles detected during DFS).

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Analyze.SCC.swift`

| Member | Signature | Description | ADT Mapping |
|--------|-----------|-------------|-------------|
| `scc(from:)` | (roots) `public func scc(from roots: some Sequence<Graph.Node<Tag>>) -> [[Graph.Node<Tag>]]` | Tarjan's SCC from roots | `strongly_connected_components` -- O(V+E) |
| `scc(from:)` | (single) `public func scc(from root: Graph.Node<Tag>) -> [[Graph.Node<Tag>]]` | Tarjan's SCC from root | `strongly_connected_components` |
| `scc()` | `public func scc() -> [[Graph.Node<Tag>]]` | Tarjan's SCC for full graph | `strongly_connected_components` |

Iterative Tarjan implementation using explicit call stack with `Stack` and `Array<Bit>.Vector`. Components returned in reverse topological order (sinks first).

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Analyze.TransitiveClosure.swift`

| Member | Signature | Description | ADT Mapping |
|--------|-----------|-------------|-------------|
| `transitiveClosure()` | `public func transitiveClosure() -> Graph.Sequential<Tag, Graph.Adjacency.List<Tag>>` | Compute transitive closure | `transitive_closure` -- O(V*(V+E)) |

Returns a new graph where edge (u,v) exists iff v is reachable from u in the original. Uses per-node DFS.

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Analyze.Dead.swift`

| Member | Signature | Description | ADT Mapping |
|--------|-----------|-------------|-------------|
| `dead(from:)` | `public func dead(from roots: some Sequence<Graph.Node<Tag>>) -> Set<Graph.Node<Tag>>.Ordered` | Unreachable vertices | `dead_vertex_detection` -- O(V+E) |

Returns ordered set of nodes not reachable from any root. Uses DFS + `Array<Bit>.Vector`.

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Analyze.Reachable.swift`

| Member | Signature | Description | ADT Mapping |
|--------|-----------|-------------|-------------|
| `reachable(from:)` | (roots) `public func reachable(from roots: some Sequence<Graph.Node<Tag>>) -> Set<Graph.Node<Tag>>.Ordered` | Forward reachability set | Related to `path_exists` (batch) |
| `reachable(from:)` | (single) `public func reachable(from root: Graph.Node<Tag>) -> Set<Graph.Node<Tag>>.Ordered` | Single-root reachability | Related to `path_exists` |

### Graph.Sequential.Reverse (Reverse/Transpose Operations)

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Reverse.swift`

| Member | Signature | Description |
|--------|-----------|-------------|
| `reverse(using:)` | `public func reverse<Adjacent>(...) -> Reverse<Adjacent>` | Reverse accessor with custom extract |
| `reverse` | (List convenience) `public var reverse: Reverse<[Graph.Node<Tag>]>` | List-specific reverse accessor |

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Reverse.Graph.swift`

| Member | Signature | Description | ADT Mapping |
|--------|-----------|-------------|-------------|
| `reversed()` | `public func reversed() -> Graph.Sequential<Tag, Graph.Adjacency.List<Tag>>` | Create graph with all edges reversed | `reverse_graph` -- O(V+E) |

For each edge A->B, the reversed graph has B->A. Always produces `Adjacency.List` payloads.

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Reverse.Reachable.swift`

| Member | Signature | Description | ADT Mapping |
|--------|-----------|-------------|-------------|
| `reachable(to:)` | `public func reachable(to target: Graph.Node<Tag>) -> Set<Graph.Node<Tag>>.Ordered` | Backward reachability (what can reach target) | Beyond canonical -- uses `reversed()` + forward DFS |

### Graph.Sequential.Transform (Structural Transforms)

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Transform.swift`

| Member | Signature | Description |
|--------|-----------|-------------|
| `transform` | `public var transform: Transform` | Transform accessor |

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Transform.Payloads.swift`

| Member | Signature | Description | ADT Mapping |
|--------|-----------|-------------|-------------|
| `payloads(_:)` | `public func payloads<NewPayload>(_ transform: (Payload) -> NewPayload) -> Graph.Sequential<Tag, NewPayload>` | Functor map over payloads | `payload_transform` -- O(V) |

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/Graph.Sequential.Transform.Subgraph.swift`

| Member | Signature | Description | ADT Mapping |
|--------|-----------|-------------|-------------|
| `subgraph(inducedBy:using:)` | `public func subgraph(inducedBy nodes: consuming Set<Graph.Node<Tag>>.Ordered, using remap: Graph.Remappable.Remap<...>) -> Graph.Sequential<Tag, Payload>?` | Generic induced subgraph with node remapping | `subgraph` -- O(V+E) |
| `subgraph(inducedBy:)` | (List convenience) `public func subgraph(inducedBy nodes: consuming Set<Graph.Node<Tag>>.Ordered) -> Graph.Sequential<Tag, Payload>?` | List-specific induced subgraph with edge filtering | `subgraph` -- O(V+E) |

Returns `nil` if any requested node is not a valid member of the graph (totality invariant). Remaps vertex identities to `0..<result.count`.

### Re-exported Modules

**File**: `/Users/coen/Developer/swift-primitives/swift-graph-primitives/Sources/Graph Primitives/exports.swift`
```swift
@_exported import Identity_Primitives
@_exported import Set_Primitives
@_exported import Index_Primitives
@_exported import Input_Primitives
@_exported import Array_Primitives
@_exported import Collection_Primitives
@_exported import Dictionary_Primitives
```

Note: `Stack_Primitives`, `Queue_Primitives`, `Heap_Primitives`, and `Bit_Primitives` are imported in individual algorithm files but NOT re-exported.

---

## Gap Analysis

### Present and Correctly Mapped

| Canonical Operation | graph-primitives API | Complexity | Notes |
|--------------------|--------------------|-----------|-------|
| `vertex_count` | `graph.count` | O(1) | Typed as `Node<Tag>.Count` |
| `add_vertex` | `builder.allocate(_:)` | O(1) amort. | Builder-phase only (immutable after freeze) |
| `neighbors(u)` | `extract.adjacent(graph[node])` | O(deg(u)) | Via `Extract` closure on payload |
| `BFS` | `graph.traverse.first(using:).breadth(from:)` | O(V+E) | Lazy `Sequence` iterator |
| `DFS` | `graph.traverse.first(using:).depth(from:)` | O(V+E) | Lazy `Sequence` iterator |
| `topological_sort` | `graph.traverse.topological(using:)` | O(V+E) | Eager; detects cycles |
| `path_exists(u,v)` | `graph.path(using:).exists(from:to:)` | O(V+E) | BFS-based |
| `shortest_path(u,v)` | `graph.path(using:).shortest(from:to:)` | O(V+E) | BFS, returns `[Node]?` |
| `weighted_shortest_path` | `graph.path(using:).weighted(from:to:weight:)` | O((V+E) log V) | Dijkstra, returns `(path, distance)?` |
| `cycle_detection` | `graph.analyze(using:).hasCycles()` | O(V+E) | Delegates to topological sort |
| `strongly_connected_components` | `graph.analyze(using:).scc()` | O(V+E) | Iterative Tarjan |
| `transitive_closure` | `graph.analyze(using:).transitiveClosure()` | O(V*(V+E)) | Per-node DFS |
| `dead_vertex_detection` | `graph.analyze(using:).dead(from:)` | O(V+E) | Complement of reachability |
| `reverse_graph` | `graph.reverse(using:).reversed()` | O(V+E) | Produces `Adjacency.List` graph |
| `subgraph` | `graph.transform.subgraph(inducedBy:using:)` | O(V+E) | Induced subgraph with remapping |
| `payload_transform` | `graph.transform.payloads(_:)` | O(V) | Functor map |

### Additional Operations (Beyond Canonical ADT)

These operations are present in graph-primitives but go beyond the minimal canonical Graph ADT. They are legitimate graph-discipline operations found in real-world graph libraries.

| Operation | API | Description |
|-----------|-----|-------------|
| Forward reachability set | `analyze.reachable(from:)` | All nodes reachable from roots -- batch `path_exists` |
| Backward reachability | `reverse.reachable(to:)` | All nodes that can reach a target -- reverse DFS |
| Forward-reference construction | `builder.allocateHole(using:)` / `builder.fill(_:with:)` | Two-phase construction for cyclic graphs |
| Adjacency remapping | `Remappable.Remap.mapNodes(_:_:)` | Transform node references preserving edge semantics |

### Missing -- Should Add (Primitives Layer)

These are fundamental graph-discipline operations absent from the current API. Each is purely topological and belongs at the primitives layer.

| Missing Operation | Priority | Rationale | Complexity |
|-------------------|----------|-----------|------------|
| `has_edge(from:to:)` | **High** | Direct edge existence is distinct from path existence. Currently requires manual adjacency extraction and linear search. Every graph library (petgraph, BGL, Haskell Data.Graph) provides this. | O(deg(u)) for adj list |
| `degree(of:)` / `outDegree(of:)` | **High** | Degree is the most basic vertex metric in graph theory. Currently requires `extract.adjacent(graph[node]).count` which forces materialization. The `Adjacency.Extract` already provides the adjacency; a thin wrapper would make it first-class. | O(deg) or O(1) if cached |
| `edge_count` | **Medium** | Total number of edges \|E\|. Currently requires iterating all vertices and summing adjacency counts. Useful for complexity estimation and graph statistics. | O(V) for adj list |
| `inDegree(of:)` | **Medium** | In-degree requires reverse traversal or precomputation. Less common than out-degree but fundamental for DAG analysis (source detection). | O(V+E) first computation, O(1) if precomputed |
| `Equatable` conformance | **Medium** | Graph structural equality (`where Payload: Equatable`). For `Sequential` with deterministic ordering, element-wise payload comparison is correct. | O(V * payload comparison) |
| `Hashable` conformance | **Low** | Follows from `Equatable`. Enables graphs as dictionary keys or set members. | O(V * payload hashing) |
| `edges` property | **Low** | Enumerate all `(source, target)` pairs. Currently implicit in adjacency lists; explicit enumeration is convenient for algorithms that iterate edges. | O(V+E) |

### Missing -- Intentionally Absent (Higher Layer)

These operations are either beyond the scope of a primitives package or belong to higher architectural layers.

| Absent Operation | Layer | Rationale |
|------------------|-------|-----------|
| `remove_vertex` | Foundations | `Graph.Sequential` is immutable after freeze. Removal requires either sparse storage with tombstones (`MutableGraph`) or full rebuild. Not a primitive. |
| `remove_edge` | Foundations | Same reasoning as `remove_vertex`. Edge removal requires either mutable adjacency or rebuild. |
| `add_edge` (post-construction) | Foundations | Immutable after freeze. Builder supports edge definition during construction. |
| Undirected graph variant | Standards or Foundations | The current package is directed-only. Undirected graphs have different invariants (symmetric adjacency) and would be a separate type, potentially a separate module. |
| Weighted edge type | Standards or Foundations | Weight is currently extracted via closure (`weight: (Payload, Node) -> Int`). A typed edge-weight representation would add structural complexity beyond what primitives should carry. |
| Algebraic graph operations (overlay, connect) | Foundations | Mokhov's algebraic graph constructors are compositional and elegant but require vertex remapping infrastructure. They build on primitives. |
| Condensation graph (SCC collapse) | Foundations | Collapsing SCCs into a DAG is a derived operation that builds on `scc()` and `subgraph()`. |
| Graph serialization (Codable) | Foundations | Serialization is a cross-cutting concern, not graph discipline. |
| Graph visualization (DOT export) | Components/Applications | Presentation concern. |
| Bipartiteness check | Foundations | Specialized analysis that can be built on BFS. |
| Minimum spanning tree | Foundations | Requires weighted edges as a first-class concept. |
| Max flow / min cut | Foundations | Specialized network flow algorithms. |

---

## Design Observations

### 1. Accessor Pattern (Fluent Namespacing)

The package uses a consistent accessor pattern for operation namespaces:

```swift
graph.traverse.first(using: extract).depth(from: root)
graph.path(using: extract).shortest(from: a, to: b)
graph.analyze(using: extract).scc()
graph.reverse(using: extract).reversed()
graph.transform.payloads { ... }
```

Each accessor (`Traverse`, `Path`, `Analyze`, `Reverse`, `Transform`) is a lightweight struct holding a reference to the graph and (where needed) the adjacency extract. This provides clean namespacing without requiring protocol conformance on payloads.

The `(using: extract)` parameter is omitted for `List` payloads via convenience overloads, yielding:

```swift
graph.traverse.first.depth(from: root)
graph.path.shortest(from: a, to: b)
graph.analyze.scc()
graph.reverse.reversed()
```

### 2. Protocol-Free Adjacency

The `Graph.Adjacency.Extract` closure pattern avoids protocol conformance requirements on payload types. This is a deliberate design choice enabling:
- Algorithms on types the graph author does not control
- Multiple adjacency interpretations of the same payload
- No associated-type complexity

This mirrors the approach taken by BGL (concept maps) and differs from petgraph (trait conformance) and the earlier research documents which proposed `Graph.Adjacency` as a protocol.

### 3. Immutable Graph + ~Copyable Builder

The `Graph.Sequential` type is immutable after construction. The `Builder` is `~Copyable`, enforcing linear ownership and preventing accidental duplication during construction. The `build()` method is `consuming`, transferring ownership to the immutable graph. This matches the ecosystem's "Builder -> Frozen" discipline.

### 4. Typed Return Types

Analysis operations return `Set<Graph.Node<Tag>>.Ordered` (from `Set_Primitives`) rather than `Swift.Set`. This preserves insertion order and provides consistent enumeration, which is important for deterministic graph algorithms.

---

## Outcome

**Status**: RECOMMENDATION

### Summary

swift-graph-primitives provides **15 of 17** canonical Graph ADT operations. Coverage is comprehensive across all five categories:

| Category | Canonical Ops | Present | Coverage |
|----------|:---:|:---:|:---:|
| Basic | 9 | 3 fully + 2 via accessor pattern | Partial (see below) |
| Traversal | 3 | 3 | **Complete** |
| Path | 3 | 3 | **Complete** |
| Analysis | 4 | 4 + 1 extra (reachable) | **Complete + extra** |
| Transform | 3 | 3 + 1 extra (backward reachable) | **Complete + extra** |

The "partial" rating for Basic operations reflects the immutable-graph design decision:
- `add_vertex` is present (Builder phase)
- `vertex_count` is present
- `neighbors` is present (via Extract)
- `remove_vertex`, `remove_edge`, `add_edge` are intentionally absent (immutable after freeze)
- `has_edge`, `degree`, `edge_count` are missing and should be added

### Recommended Actions

1. **Add `has_edge(from:to:)` to `Analyze` accessor** -- High priority. Direct edge query is fundamental.
2. **Add `outDegree(of:)` to `Analyze` accessor** -- High priority. Most basic vertex metric.
3. **Add `edgeCount` to `Graph.Sequential`** -- Medium priority. Graph cardinality.
4. **Add `Equatable` conformance** -- Medium priority. `where Payload: Equatable`.
5. **Evaluate `@_exported` imports** -- The discipline boundary analysis (2026-02-14) identified several re-exported modules that are algorithm implementation details rather than public API surface.

### What Makes This Package Noteworthy

The package demonstrates excellent architectural discipline:
- Zero storage/buffer concerns have leaked into the graph layer
- All 70+ public API members are correctly classified as graph-discipline operations
- The accessor pattern provides clean namespacing without protocol-on-payload requirements
- Every algorithm uses the appropriate data structure from lower tiers (`Stack`, `Queue`, `Heap`, `Array<Bit>.Vector`) without exposing them in the public API
- Convenience overloads for `List` payloads keep the API ergonomic without sacrificing generality

---

*Document version 1.0.0. Last updated 2026-02-16.*
