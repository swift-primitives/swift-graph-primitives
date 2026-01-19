extension Graph {
    /// A payload that references other nodes in the graph.
    ///
    /// Conform to this protocol to define the edges emanating from a node.
    /// The `adjacent` property returns the nodes that this payload references,
    /// enabling graph traversal and analysis algorithms.
    ///
    /// ## Example
    ///
    /// ```swift
    /// enum Tag {}
    /// struct TreeNode: Graph.Adjacency {
    ///     let children: [Graph.Node<Tag>]
    ///     var adjacent: [Graph.Node<Tag>] { children }
    /// }
    /// ```
    public protocol Adjacency<Tag> {
        /// The phantom type tag identifying the graph.
        associatedtype Tag

        /// The sequence type for adjacent nodes.
        associatedtype Adjacent: Sequence<Node<Tag>>

        /// The nodes this payload references (outgoing edges).
        var adjacent: Adjacent { get }
    }
}
