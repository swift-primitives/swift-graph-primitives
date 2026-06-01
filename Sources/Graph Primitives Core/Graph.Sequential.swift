public import Array_Primitives
public import Index_Primitives
public import Tagged_Primitives
public import Tagged_Collection_Primitives
public import Vector_Primitives

extension Graph {
    /// An immutable graph with sequentially-allocated nodes.
    ///
    /// `Sequential` stores payloads in a dense array where each payload's index
    /// corresponds to its node identity. This provides O(1) node lookup and
    /// cache-friendly traversal.
    ///
    /// The graph is immutable after construction via `Builder`. Use protocols like
    /// `Adjacency` on the `Payload` type to define edges.
    ///
    /// ## Example
    ///
    /// ```swift
    /// enum Tag {}
    /// var builder = Graph.Sequential<Tag, String>.Builder()
    /// let a = builder.allocate("A")
    /// let b = builder.allocate("B")
    /// let graph = builder.build()
    /// print(graph[a])  // "A"
    /// ```
    public struct Sequential<Tag, Payload> {
        public let storage: Tagged<Tag, Array<Payload>>

        @usableFromInline
        init(storage: Tagged<Tag, Array<Payload>>) {
            self.storage = storage
        }

        /// The number of nodes in the graph.
        @inlinable
        public var count: Node<Tag>.Count {
            storage.count
        }

        /// Whether the graph contains no nodes.
        @inlinable
        public var isEmpty: Bool { storage.isEmpty }

        /// Accesses the payload for a given node.
        ///
        /// - Precondition: The node must be valid for this graph.
        @inlinable
        public subscript(node: Node<Tag>) -> Payload {
            storage[node]
        }

        /// All nodes in the graph, in allocation order.
        ///
        /// Returns a `Vector_Primitives.Vector<Node<Tag>>` — an ecosystem-native,
        /// zero-allocation finite-domain functor (`Vec n A = Fin n -> A`) that
        /// generates each `Node<Tag>` on demand from the integer domain
        /// `0..<count`. `Vector` conforms to both `Sequence_Primitives.Sequence.\`Protocol\``
        /// and `Swift.Sequence` (when `Bound: Copyable`, which holds here),
        /// so existing consumers using `for-in`, `.forEach`, `.map`, or
        /// passing to `some Swift.Sequence<Node<Tag>>` parameters all keep
        /// working unchanged.
        ///
        /// Returning `Vector` concretely (rather than `some Swift.Sequence<Node<Tag>>`)
        /// also sidesteps a Swift 6.3.1 `PerformanceSILLinker` SIL-deserialization
        /// mismatch where cross-module `@inlinable` callers see the opaque
        /// form (`@_opaqueReturnTypeOf(...) __<...>`) but the SIL contains
        /// the substituted concrete type. The Vector-backed accessor is the
        /// structurally correct shape, not just a workaround — the prior
        /// `some Swift.Sequence<...>` form was reaching for exactly the
        /// "lazy index → typed bound" abstraction Vector codifies.
        @inlinable
        public var nodes: Vector<Node<Tag>> {
            Vector(count: count.retag(Vector<Node<Tag>>.self)) { vIndex in
                Node<Tag>(_unchecked: vIndex.position)
            }
        }
    }
}

extension Graph.Sequential: Sendable where Payload: Sendable {}
