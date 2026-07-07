public import Tagged_Primitives

extension Graph.Sequential.Traverse {
    /// Returns a first-visit accessor with the given adjacency extract.
    @inlinable
    public func first<Adjacent: Swift.Sequence<Graph.Node<Tag>>>(
        using extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
    ) -> First<Adjacent> {
        First(graph: graph, extract: extract)
    }

    /// Accessor type providing first-visit traversal strategies.
    @frozen
    public struct First<Adjacent: Swift.Sequence<Graph.Node<Tag>>> {
        /// The underlying graph.
        public let graph: Graph.Sequential<Tag, Payload>

        /// The adjacency extract used to read edges from each node's payload.
        public let extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>

        @usableFromInline
        init(graph: Graph.Sequential<Tag, Payload>, extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>) {
            self.graph = graph
            self.extract = extract
        }
    }
}

// Convenience for List payload
extension Graph.Sequential.Traverse where Payload == Graph.Adjacency.List<Tag> {
    /// Accessor for first-visit traversal strategies using the canonical List extract.
    @inlinable
    public var first: First<[Graph.Node<Tag>]> {
        first(using: .list)
    }
}
