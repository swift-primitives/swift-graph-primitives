public import Identity_Primitives
public import Index_Primitives
public import Array_Primitives

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
    public struct Sequential<Tag, Payload>: Sendable where Payload: Sendable {
        @usableFromInline
        let storage: Array<Payload>.Indexed<Tag>

        @usableFromInline
        init(storage: Array<Payload>.Indexed<Tag>) {
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
        @inlinable
        public var nodes: some Swift.Sequence<Node<Tag>> {
            (0..<storage._storage.count).lazy.map { Node<Tag>(__unchecked: (), position: $0) }
        }
    }
}

