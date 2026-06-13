public import Tagged_Primitives

extension Graph.Sequential {
    /// Returns a reverse accessor with the given adjacency extract.
    @inlinable
    public func reverse<Adjacent: Swift.Sequence<Graph.Node<Tag>>>(
        using extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
    ) -> Reverse<Adjacent> {
        Reverse(graph: self, extract: extract)
    }

    /// Accessor for reverse graph operations.
    @frozen
    public struct Reverse<Adjacent: Swift.Sequence<Graph.Node<Tag>>> {
        public let graph: Graph.Sequential<Tag, Payload>

        public let extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>

        @usableFromInline
        init(graph: Graph.Sequential<Tag, Payload>, extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>) {
            self.graph = graph
            self.extract = extract
        }
    }
}

// Convenience for List payload
extension Graph.Sequential where Payload == Graph.Adjacency.List<Tag> {
    /// Reverse accessor using the canonical List extract.
    @inlinable
    public var reverse: Reverse<[Graph.Node<Tag>]> {
        reverse(using: .list)
    }
}
