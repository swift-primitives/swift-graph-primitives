extension Graph.Adjacency {
    /// Extracts adjacent nodes from a payload.
    ///
    /// Use this to enable graph algorithms on custom payload types without protocols.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct MyPayload {
    ///     let targets: [Graph.Node<Tag>]
    /// }
    ///
    /// let extract = Graph.Adjacency.Extract<MyPayload, Tag, [Graph.Node<Tag>]> {
    ///     $0.targets
    /// }
    /// graph.analyze(using: extract).reachable(from: root)
    /// ```
    @frozen
    public struct Extract<Payload, Tag: ~Copyable & ~Escapable, Adjacent: Swift.Sequence<Graph.Node<Tag>>> {
        @usableFromInline
        let _adjacent: (Payload) -> Adjacent

        /// Creates an extract from a closure that reads adjacent nodes from a payload.
        @inlinable
        public init(adjacent: @escaping (Payload) -> Adjacent) {
            self._adjacent = adjacent
        }

        /// Returns the nodes adjacent to `payload`.
        @inlinable
        public func adjacent(_ payload: Payload) -> Adjacent {
            _adjacent(payload)
        }
    }
}
