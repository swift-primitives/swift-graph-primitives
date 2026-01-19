extension Graph.Sequential.Traverse where Payload: Graph.Adjacency, Payload.Tag == Tag {
    /// Returns a topological ordering of nodes reachable from the given roots.
    ///
    /// The returned sequence iterates nodes in an order where each node appears
    /// before any nodes it references. If the graph contains cycles, the sequence
    /// will be empty and `hasCycles` will be true.
    ///
    /// - Parameter roots: The nodes to start from.
    /// - Returns: A topological ordering, or an empty sequence if cycles exist.
    @inlinable
    public func topological(
        from roots: some Sequence<Graph.Node<Tag>>
    ) -> Graph.Traversal.Topological<Tag, Payload> {
        Graph.Traversal.Topological(storage: graph.storage, roots: roots)
    }

    /// Returns a topological ordering of nodes reachable from a single root.
    ///
    /// - Parameter root: The node to start from.
    /// - Returns: A topological ordering, or an empty sequence if cycles exist.
    @inlinable
    public func topological(
        from root: Graph.Node<Tag>
    ) -> Graph.Traversal.Topological<Tag, Payload> {
        topological(from: CollectionOfOne(root))
    }

    /// Returns a topological ordering of all nodes in the graph.
    ///
    /// - Returns: A topological ordering, or an empty sequence if cycles exist.
    @inlinable
    public func topological() -> Graph.Traversal.Topological<Tag, Payload> {
        topological(from: graph.nodes)
    }
}
