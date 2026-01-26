extension Graph.Remappable {
    /// Remaps node references within a payload.
    ///
    /// ## Invariants
    ///
    /// - **Node-domain**: `mapNodes` preserves adjacency semantics under node renaming.
    ///   Edge multiplicity and order are preserved.
    /// - **Totality**: `transform` closure must be total over all nodes referenced by this payload.
    public struct Remap<Payload, Tag, Adjacent: Swift.Sequence<Graph.Node<Tag>>> {
        @usableFromInline
        let _adjacent: (Payload) -> Adjacent

        @usableFromInline
        let _mapNodes: (Payload, (Graph.Node<Tag>) -> Graph.Node<Tag>) -> Payload

        @inlinable
        public init(
            adjacent: @escaping (Payload) -> Adjacent,
            mapNodes: @escaping (Payload, (Graph.Node<Tag>) -> Graph.Node<Tag>) -> Payload
        ) {
            self._adjacent = adjacent
            self._mapNodes = mapNodes
        }

        @inlinable
        public func adjacent(_ payload: Payload) -> Adjacent {
            _adjacent(payload)
        }

        @inlinable
        public func mapNodes(_ payload: Payload, _ transform: (Graph.Node<Tag>) -> Graph.Node<Tag>) -> Payload {
            _mapNodes(payload, transform)
        }

        /// Convert to an adjacency-only extract.
        @inlinable
        public var extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent> {
            Graph.Adjacency.Extract(adjacent: _adjacent)
        }
    }
}

// Canonical remap for List
extension Graph.Remappable.Remap where Payload == Graph.Adjacency.List<Tag>, Adjacent == [Graph.Node<Tag>] {
    /// Remap for the canonical `List` payload type.
    @inlinable
    public static var list: Self {
        Self(
            adjacent: { $0.adjacent },
            mapNodes: { payload, transform in
                Graph.Adjacency.List<Tag>(adjacent: payload.adjacent.map(transform))
            }
        )
    }
}
