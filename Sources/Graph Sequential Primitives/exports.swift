@_exported public import Graph_Primitive
// `Graph.Sequential` and its operation namespaces are built over the node identity
// (Graph Index Primitives) and the adjacency payload abstraction (Graph Adjacency
// Primitives); re-export both so the representation's consumers and this target's
// own sibling files (Builder/Analyze/Path/Reverse/…) see `Graph.Node` /
// `Graph.Adjacency`. `Graph.Default` is folded into this target (its only consumer
// is `Graph.Sequential.Builder`).
@_exported public import Graph_Index_Primitives
@_exported public import Graph_Adjacency_Primitives
@_exported public import Array_Primitives
@_exported public import Tagged_Primitives
// Sequential publicly vends `Vector<Node<Tag>>` via `Graph.Sequential.nodes`; under
// MemberImportVisibility (SE-0444) consumers iterating `graph.nodes` need the
// Vector iteration witnesses (`makeIterator()` in Vector_Primitives, `next()` in
// Vector_Primitive, re-exported by the umbrella) visible through the chain.
@_exported public import Vector_Primitives
