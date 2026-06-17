public import Buffer_Linear_Primitive
public import Graph_Sequential_Primitives
import Shared_Primitive

extension Graph.Sequential.Traverse.First {
    /// Returns a depth-first traversal starting from the given roots.
    ///
    /// - Parameter roots: The nodes to start traversal from.
    /// - Returns: A sequence yielding (node, payload) pairs in depth-first order.
    @inlinable
    public func depth(
        from roots: some Swift.Sequence<Graph.Node<Tag>>
    ) -> Graph.Traversal.First.Depth<Tag, Payload, Adjacent> {
        Graph.Traversal.First.Depth(storage: graph.storage, roots: roots, extract: extract)
    }

    /// Returns a depth-first traversal starting from a single root.
    ///
    /// - Parameter root: The node to start traversal from.
    /// - Returns: A sequence yielding (node, payload) pairs in depth-first order.
    @inlinable
    public func depth(
        from root: Graph.Node<Tag>
    ) -> Graph.Traversal.First.Depth<Tag, Payload, Adjacent> {
        depth(from: Swift.CollectionOfOne(root))
    }
}
