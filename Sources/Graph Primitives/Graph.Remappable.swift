extension Graph {
    /// A payload whose node references can be remapped.
    ///
    /// Conform to this protocol when payloads need to have their node references
    /// transformed, such as during subgraph extraction or graph rewriting.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct Edge: Graph.Remappable {
    ///     let target: Graph.Node<Tag>
    ///
    ///     var adjacent: CollectionOfOne<Graph.Node<Tag>> {
    ///         CollectionOfOne(target)
    ///     }
    ///
    ///     func mapNodes(_ transform: (Graph.Node<Tag>) -> Graph.Node<Tag>) -> Self {
    ///         Edge(target: transform(target))
    ///     }
    /// }
    /// ```
    public protocol Remappable<Tag>: Adjacency {
        /// Returns a copy of this payload with node references transformed.
        ///
        /// - Parameter transform: A function mapping old node identities to new ones.
        /// - Returns: A new payload with transformed node references.
        func mapNodes(_ transform: (Node<Tag>) -> Node<Tag>) -> Self
    }
}
