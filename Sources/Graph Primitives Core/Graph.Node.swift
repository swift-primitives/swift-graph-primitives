public import Index_Primitives

extension Graph {
    /// A node's identity within a graph.
    ///
    /// The `Tag` parameter prevents mixing nodes from different graphs at compile time.
    /// This provides zero-cost type safety using `Affine.Discrete.Position` as the
    /// underlying storage for efficient indexing into sequential storage.
    ///
    /// ## Example
    ///
    /// ```swift
    /// enum MyGraphTag {}
    /// let node: Graph.Node<MyGraphTag> = .zero
    /// ```
    public typealias Node<Tag: ~Copyable & ~Escapable> = Index<Tag>
}
