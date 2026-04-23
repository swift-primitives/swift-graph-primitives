public import Tagged_Primitives

extension Graph.Sequential {
    /// Returns an analyze accessor with the given adjacency extract.
    @inlinable
    public func analyze<Adjacent: Swift.Sequence<Graph.Node<Tag>>>(
        using extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
    ) -> Analyze<Adjacent> {
        Analyze(graph: self, extract: extract)
    }

    /// Accessor for graph analysis operations.
    public struct Analyze<Adjacent: Swift.Sequence<Graph.Node<Tag>>> {
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
    /// Analyze accessor using the canonical List extract.
    @inlinable
    public var analyze: Analyze<[Graph.Node<Tag>]> {
        analyze(using: .list)
    }
}
