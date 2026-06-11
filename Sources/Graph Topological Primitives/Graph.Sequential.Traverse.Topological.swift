public import Buffer_Linear_Primitive
public import Vector_Primitives

extension Graph.Sequential.Traverse {
    /// Returns a topological ordering of nodes reachable from the given roots.
    ///
    /// The returned sequence iterates nodes in an order where each node appears
    /// before any nodes it references. If the graph contains cycles, the sequence
    /// will be empty and `hasCycles` will be true.
    ///
    /// - Parameters:
    ///   - roots: The nodes to start from.
    ///   - extract: The adjacency extract for the payload type.
    /// - Returns: A topological ordering, or an empty sequence if cycles exist.
    @inlinable
    public func topological<Adjacent: Swift.Sequence<Graph.Node<Tag>>>(
        from roots: some Swift.Sequence<Graph.Node<Tag>>,
        using extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
    ) -> Graph.Traversal.Topological<Tag, Payload, Adjacent> {
        Graph.Traversal.Topological(storage: graph.storage, roots: roots, extract: extract)
    }

    /// Returns a topological ordering of nodes reachable from a single root.
    ///
    /// - Parameters:
    ///   - root: The node to start from.
    ///   - extract: The adjacency extract for the payload type.
    /// - Returns: A topological ordering, or an empty sequence if cycles exist.
    @inlinable
    public func topological<Adjacent: Swift.Sequence<Graph.Node<Tag>>>(
        from root: Graph.Node<Tag>,
        using extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
    ) -> Graph.Traversal.Topological<Tag, Payload, Adjacent> {
        topological(from: Swift.CollectionOfOne(root), using: extract)
    }

    /// Returns a topological ordering of all nodes in the graph.
    ///
    /// - Parameter extract: The adjacency extract for the payload type.
    /// - Returns: A topological ordering, or an empty sequence if cycles exist.
    @inlinable
    public func topological<Adjacent: Swift.Sequence<Graph.Node<Tag>>>(
        using extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
    ) -> Graph.Traversal.Topological<Tag, Payload, Adjacent> {
        topological(from: graph.nodes, using: extract)
    }
}

// Convenience for List payload
extension Graph.Sequential.Traverse where Payload == Graph.Adjacency.List<Tag> {
    /// Returns a topological ordering of nodes reachable from the given roots.
    ///
    /// - Parameter roots: The nodes to start from.
    /// - Returns: A topological ordering, or an empty sequence if cycles exist.
    @inlinable
    public func topological(
        from roots: some Swift.Sequence<Graph.Node<Tag>>
    ) -> Graph.Traversal.Topological<Tag, Payload, [Graph.Node<Tag>]> {
        topological(from: roots, using: .list)
    }

    /// Returns a topological ordering of nodes reachable from a single root.
    ///
    /// - Parameter root: The node to start from.
    /// - Returns: A topological ordering, or an empty sequence if cycles exist.
    @inlinable
    public func topological(
        from root: Graph.Node<Tag>
    ) -> Graph.Traversal.Topological<Tag, Payload, [Graph.Node<Tag>]> {
        topological(from: Swift.CollectionOfOne(root), using: .list)
    }

    /// Returns a topological ordering of all nodes in the graph.
    ///
    /// - Returns: A topological ordering, or an empty sequence if cycles exist.
    @inlinable
    public func topological() -> Graph.Traversal.Topological<Tag, Payload, [Graph.Node<Tag>]> {
        topological(from: graph.nodes, using: .list)
    }
}
