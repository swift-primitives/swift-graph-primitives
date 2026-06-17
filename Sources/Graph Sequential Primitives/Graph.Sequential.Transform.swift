extension Graph.Sequential {
    /// Returns a transform accessor for this graph.
    @inlinable
    public var transform: Transform { Transform(graph: self) }

    /// Accessor for graph transformation operations.
    @frozen
    public struct Transform {
        public let graph: Graph.Sequential<Tag, Payload>

        @usableFromInline
        init(graph: Graph.Sequential<Tag, Payload>) {
            self.graph = graph
        }
    }
}
