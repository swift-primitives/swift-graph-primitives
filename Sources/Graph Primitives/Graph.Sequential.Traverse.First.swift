extension Graph.Sequential.Traverse where Payload: Graph.Adjacency, Payload.Tag == Tag {
    /// Accessor for first-visit traversal strategies.
    @inlinable
    public var first: First { First(graph: graph) }

    /// Accessor type providing first-visit traversal strategies.
    public struct First: Sendable where Payload: Sendable {
        @usableFromInline
        let graph: Graph.Sequential<Tag, Payload>

        @usableFromInline
        init(graph: Graph.Sequential<Tag, Payload>) {
            self.graph = graph
        }

        /// Returns a depth-first traversal starting from the given roots.
        ///
        /// - Parameter roots: The nodes to start traversal from.
        /// - Returns: A sequence yielding (node, payload) pairs in depth-first order.
        @inlinable
        public func depth(
            from roots: some Sequence<Graph.Node<Tag>>
        ) -> Graph.Traversal.First.Depth<Tag, Payload> {
            Graph.Traversal.First.Depth(storage: graph.storage, roots: roots)
        }

        /// Returns a depth-first traversal starting from a single root.
        ///
        /// - Parameter root: The node to start traversal from.
        /// - Returns: A sequence yielding (node, payload) pairs in depth-first order.
        @inlinable
        public func depth(
            from root: Graph.Node<Tag>
        ) -> Graph.Traversal.First.Depth<Tag, Payload> {
            depth(from: CollectionOfOne(root))
        }

        /// Returns a breadth-first traversal starting from the given roots.
        ///
        /// - Parameter roots: The nodes to start traversal from.
        /// - Returns: A sequence yielding (node, payload) pairs in breadth-first order.
        @inlinable
        public func breadth(
            from roots: some Sequence<Graph.Node<Tag>>
        ) -> Graph.Traversal.First.Breadth<Tag, Payload> {
            Graph.Traversal.First.Breadth(storage: graph.storage, roots: roots)
        }

        /// Returns a breadth-first traversal starting from a single root.
        ///
        /// - Parameter root: The node to start traversal from.
        /// - Returns: A sequence yielding (node, payload) pairs in breadth-first order.
        @inlinable
        public func breadth(
            from root: Graph.Node<Tag>
        ) -> Graph.Traversal.First.Breadth<Tag, Payload> {
            breadth(from: CollectionOfOne(root))
        }
    }
}
