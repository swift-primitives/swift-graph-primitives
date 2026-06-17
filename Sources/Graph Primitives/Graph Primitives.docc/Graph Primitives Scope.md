# Graph Primitives Scope

The identity surface of `swift-graph-primitives`, and what lies outside it.

## Identity

`swift-graph-primitives` provides the substrate for **immutable directed graphs with
sequentially-allocated nodes** — typed node identity, the adjacency-payload abstraction,
the dense `Graph.Sequential` representation built by a `Builder`, and the traversal,
analysis, path-finding, and transformation algorithms that operate over it. Node identity
is phantom-typed by `Tag`, so nodes from different graphs are distinct types.

## Core targets

Foundational sub-namespaces ([MOD-031], one target per sub-namespace):

- **Graph Primitive** — the `Graph` namespace; zero-dependency root ([MOD-017]).
- **Graph Index Primitives** — `Graph.Node` / `Graph.Index`, the typed node identity.
- **Graph Adjacency Primitives** — `Graph.Adjacency`, the adjacency-payload abstraction.
- **Graph Traversal Primitives** — `Graph.Traversal`, traversal-order markers.
- **Graph Sequential Primitives** — `Graph.Sequential` with its `Builder` and the
  `Analyze` / `Path` / `Transform` / `Reverse` / `Traverse` operation namespaces. The
  `Graph.Default` factories are folded in here: their only consumer is
  `Graph.Sequential.Builder` ([MOD-008], no independent consumer).
- **Graph Remappable Primitives** — `Graph.Remappable`, node remapping.

Algorithm sub-namespaces, each an extension over `Graph.Sequential.*`:

- Traversal: **DFS**, **BFS**, **Topological**.
- Analysis: **Reachable**, **Dead**, **SCC**, **Cycles**, **Transitive Closure**.
- Path: **Path Exists**, **Shortest Path**, **Weighted Path**.
- Transform: **Payload Map**, **Subgraph**.
- Reverse: **Reverse**, **Backward Reachable**.

## Out of scope

- **Mutable / incremental graphs** — `Graph.Sequential` is immutable after `build()`.
  Mutation lives in consumer code or a future representation, not this substrate.
- **Alternative representations** (adjacency-matrix, edge-list) — a future sibling
  target/package (`Graph.Matrix`, …), never folded into `Graph.Sequential`.
- **An edge-weight model** beyond what an algorithm needs internally — weights are
  supplied by the consumer's payload or closure; this package stores no weight type.
- **Graph generation** (random/test graphs, parsers) — consumer code or a fixtures package.
- **Rendering / layout / visualization** — a higher layer, never an L1 primitive.
- **Persistence / serialization** — a codec package or consumer code.

## Evaluation rule

Sub-target additions are evaluated against this scope. If a proposed addition is OUT of
scope, it extracts to a sibling package, not into this one. A new algorithm that operates
over `Graph.Sequential` is in scope and joins as a new `Graph.Sequential.*`-extending
target ([MOD-031]); a new *representation* is out of scope for the `Sequential` substrate
and belongs in its own sibling.
