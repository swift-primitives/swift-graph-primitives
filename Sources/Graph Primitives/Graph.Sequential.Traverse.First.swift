public import Identity_Primitives

extension Graph.Sequential.Traverse {
    /// Returns a first-visit accessor with the given adjacency extract.
    @inlinable
    public func first<Adjacent: Swift.Sequence<Graph.Node<Tag>>>(
        using extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
    ) -> First<Adjacent> {
        First(graph: graph, extract: extract)
    }

    /// Accessor type providing first-visit traversal strategies.
    public struct First<Adjacent: Swift.Sequence<Graph.Node<Tag>>> {
        @usableFromInline
        let graph: Graph.Sequential<Tag, Payload>

        @usableFromInline
        let extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>

        @usableFromInline
        init(graph: Graph.Sequential<Tag, Payload>, extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>) {
            self.graph = graph
            self.extract = extract
        }

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
}

// Convenience for List payload
extension Graph.Sequential.Traverse where Payload == Graph.Adjacency.List<Tag> {
    /// Accessor for first-visit traversal strategies using the canonical List extract.
    @inlinable
    public var first: First<[Graph.Node<Tag>]> {
        first(using: .list)
    }
}
