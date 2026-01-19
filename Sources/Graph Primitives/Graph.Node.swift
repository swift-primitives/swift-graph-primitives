public import Identity_Primitives

extension Graph {
    /// A node's identity within a graph.
    ///
    /// The `Tag` parameter prevents mixing nodes from different graphs at compile time.
    /// This provides zero-cost type safety while using a simple `Int` as the underlying
    /// storage for efficient indexing into sequential storage.
    ///
    /// ## Example
    ///
    /// ```swift
    /// enum MyGraphTag {}
    /// let node: Graph.Node<MyGraphTag> = 0
    /// ```
    public typealias Node<Tag> = Tagged<Tag, Int>
}
