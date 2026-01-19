public import Identity_Primitives

extension Graph.Traversal.First {
    /// Breadth-first traversal over a graph.
    ///
    /// Visits nodes in breadth-first order starting from the specified roots.
    /// Each node is visited at most once, even if reachable from multiple paths.
    ///
    /// ## Example
    ///
    /// ```swift
    /// for (node, payload) in graph.traverse.first.breadth(from: root) {
    ///     print(payload)
    /// }
    /// ```
    public struct Breadth<Tag, Payload: Graph.Adjacency>: Sequence, IteratorProtocol
    where Payload.Tag == Tag {
        public typealias Element = (node: Graph.Node<Tag>, payload: Payload)

        @usableFromInline
        let storage: [Payload]

        @usableFromInline
        var queue: [Graph.Node<Tag>]

        @usableFromInline
        var queueIndex: Int

        @usableFromInline
        var visited: Set<Graph.Node<Tag>>

        @usableFromInline
        init(storage: [Payload], roots: some Sequence<Graph.Node<Tag>>) {
            self.storage = storage
            self.queue = []
            self.queueIndex = 0
            self.visited = []

            for root in roots {
                if visited.insert(root).inserted {
                    queue.append(root)
                }
            }
        }

        @inlinable
        public mutating func next() -> Element? {
            guard queueIndex < queue.count else { return nil }

            let node = queue[queueIndex]
            queueIndex += 1

            let payload = storage[node.rawValue]

            for adjacent in payload.adjacent {
                if visited.insert(adjacent).inserted {
                    queue.append(adjacent)
                }
            }

            return (node, payload)
        }
    }
}

extension Graph.Sequential where Payload: Graph.Adjacency, Payload.Tag == Tag {
    /// Returns a breadth-first traversal starting from the given roots.
    ///
    /// - Parameter roots: The nodes to start traversal from.
    /// - Returns: A sequence yielding (node, payload) pairs in breadth-first order.
    @inlinable
    public func breadth(
        from roots: some Sequence<Graph.Node<Tag>>
    ) -> Graph.Traversal.First.Breadth<Tag, Payload> {
        Graph.Traversal.First.Breadth(storage: storage, roots: roots)
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
