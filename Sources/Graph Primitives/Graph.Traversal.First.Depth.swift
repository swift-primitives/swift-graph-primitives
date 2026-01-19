public import Identity_Primitives

extension Graph.Traversal.First {
    /// Depth-first traversal over a graph.
    ///
    /// Visits nodes in depth-first order starting from the specified roots.
    /// Each node is visited at most once, even if reachable from multiple paths.
    ///
    /// The traversal visits adjacent nodes in reverse adjacency order (last adjacent
    /// node is visited first). This is a consequence of using a stack without
    /// requiring `BidirectionalCollection` conformance from the adjacency sequence.
    /// If left-to-right visitation is important, ensure your payload's adjacency
    /// is ordered accordingly.
    ///
    /// ## Example
    ///
    /// ```swift
    /// for (node, payload) in graph.traverse.first.depth(from: root) {
    ///     print(payload)
    /// }
    /// ```
    public struct Depth<Tag, Payload: Graph.Adjacency>: Sequence, IteratorProtocol
    where Payload.Tag == Tag {
        public typealias Element = (node: Graph.Node<Tag>, payload: Payload)

        @usableFromInline
        let storage: [Payload]

        @usableFromInline
        var stack: [Graph.Node<Tag>]

        @usableFromInline
        var visited: Set<Graph.Node<Tag>>

        @usableFromInline
        init(storage: [Payload], roots: some Sequence<Graph.Node<Tag>>) {
            self.storage = storage
            self.stack = Array(roots)
            self.visited = []
        }

        @inlinable
        public mutating func next() -> Element? {
            while let node = stack.popLast() {
                guard visited.insert(node).inserted else { continue }

                let payload = storage[node.rawValue]

                for adjacent in payload.adjacent {
                    if !visited.contains(adjacent) {
                        stack.append(adjacent)
                    }
                }

                return (node, payload)
            }
            return nil
        }
    }
}

extension Graph.Sequential where Payload: Graph.Adjacency, Payload.Tag == Tag {
    /// Returns a depth-first traversal starting from the given roots.
    ///
    /// - Parameter roots: The nodes to start traversal from.
    /// - Returns: A sequence yielding (node, payload) pairs in depth-first order.
    @inlinable
    public func depth(
        from roots: some Sequence<Graph.Node<Tag>>
    ) -> Graph.Traversal.First.Depth<Tag, Payload> {
        Graph.Traversal.First.Depth(storage: storage, roots: roots)
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
}
