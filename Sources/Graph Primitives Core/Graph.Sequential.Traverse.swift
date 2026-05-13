extension Graph.Sequential {
    /// Accessor for traversal operations on this graph.
    @inlinable
    public var traverse: Traverse { Traverse(graph: self) }

    /// Accessor type providing traversal operations.
    public struct Traverse {
        public let graph: Graph.Sequential<Tag, Payload>

        @usableFromInline
        init(graph: Graph.Sequential<Tag, Payload>) {
            self.graph = graph
        }
    }
}

extension Graph.Sequential.Traverse: Sendable where Payload: Sendable {}
