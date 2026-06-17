public import Buffer_Linear_Primitive
public import Graph_Sequential_Primitives

extension Graph.Sequential.Traverse.First {
    /// Returns a breadth-first traversal starting from the given roots.
    ///
    /// - Parameter roots: The nodes to start traversal from.
    /// - Returns: A sequence yielding (node, payload) pairs in breadth-first order.
    @inlinable
    public func breadth(
        from roots: some Swift.Sequence<Graph.Node<Tag>>
    ) -> Graph.Traversal.First.Breadth<Tag, Payload, Adjacent> {
        Graph.Traversal.First.Breadth(storage: graph.storage, roots: roots, extract: extract)
    }

    /// Returns a breadth-first traversal starting from a single root.
    ///
    /// - Parameter root: The node to start traversal from.
    /// - Returns: A sequence yielding (node, payload) pairs in breadth-first order.
    @inlinable
    public func breadth(
        from root: Graph.Node<Tag>
    ) -> Graph.Traversal.First.Breadth<Tag, Payload, Adjacent> {
        breadth(from: Swift.CollectionOfOne(root))
    }
}
