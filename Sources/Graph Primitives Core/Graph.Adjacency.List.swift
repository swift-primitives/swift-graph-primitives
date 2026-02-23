extension Graph.Adjacency {
    /// Simple adjacency-list payload for computed graphs.
    ///
    /// Adjacency order is insertion order but **not guaranteed stable** across operations.
    public struct List<Tag>: Sendable {
        public var adjacent: [Graph.Node<Tag>]

        @inlinable
        public init(adjacent: [Graph.Node<Tag>] = []) {
            self.adjacent = adjacent
        }
    }
}

// Canonical extract for List
extension Graph.Adjacency.Extract where Payload == Graph.Adjacency.List<Tag>, Adjacent == [Graph.Node<Tag>] {
    /// Extract for the canonical `List` payload type.
    @inlinable
    public static var list: Self {
        Self { $0.adjacent }
    }
}
