public import Identity_Primitives

extension Graph.Traversal {
    /// Topological ordering of nodes in a directed acyclic graph.
    ///
    /// Computes the full ordering eagerly upon construction, returning nodes in an
    /// order where each node appears before any nodes it references. If the graph
    /// contains cycles, `hasCycles` will be `true` and the sequence will be empty.
    ///
    /// Unlike depth-first and breadth-first traversals which are lazy iterators,
    /// topological ordering requires computing the complete result to detect cycles.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let order = graph.traverse.topological(from: root)
    /// if !order.hasCycles {
    ///     for (node, payload) in order {
    ///         // Process in dependency order
    ///     }
    /// }
    /// ```
    public struct Topological<Tag, Payload: Graph.Adjacency>: Sequence
    where Payload.Tag == Tag {
        public typealias Element = (node: Graph.Node<Tag>, payload: Payload)

        @usableFromInline
        let elements: [(node: Graph.Node<Tag>, payload: Payload)]?

        @usableFromInline
        init(storage: [Payload], roots: some Sequence<Graph.Node<Tag>>) {
            self.elements = Self.computeOrder(storage: storage, roots: roots)
        }

        @usableFromInline
        static func computeOrder(
            storage: [Payload],
            roots: some Sequence<Graph.Node<Tag>>
        ) -> [Element]? {
            let count = storage.count
            guard count > 0 else { return [] }

            // Array-backed state: O(1) lookup by node.rawValue
            var visited = [Bool](repeating: false, count: count)
            var visiting = [Bool](repeating: false, count: count)
            var result: [Element] = []
            result.reserveCapacity(count)

            // Stack uses two phases: true = entering, false = leaving
            var stack: [(node: Graph.Node<Tag>, entering: Bool)] = []

            for root in roots {
                let rootIndex = root.rawValue
                if visited[rootIndex] { continue }

                stack.append((root, true))

                while let (node, entering) = stack.popLast() {
                    let nodeIndex = node.rawValue

                    if entering {
                        // Entering: check state and push adjacents
                        if visited[nodeIndex] { continue }
                        if visiting[nodeIndex] {
                            // Cycle detected: node is on current DFS path
                            return nil
                        }

                        visiting[nodeIndex] = true

                        // Push leave action first (will be processed after all adjacents)
                        stack.append((node, false))

                        // Push adjacents to visit
                        let payload = storage[nodeIndex]
                        for adjacent in payload.adjacent {
                            let adjIndex = adjacent.rawValue
                            if !visited[adjIndex] && !visiting[adjIndex] {
                                stack.append((adjacent, true))
                            } else if visiting[adjIndex] {
                                // Cycle detected
                                return nil
                            }
                        }
                    } else {
                        // Leaving: mark visited and record in result
                        visiting[nodeIndex] = false
                        visited[nodeIndex] = true
                        result.append((node, storage[nodeIndex]))
                    }
                }
            }

            result.reverse()
            return result
        }

        /// Whether the graph contains cycles (making topological order impossible).
        @inlinable
        public var hasCycles: Bool { elements == nil }

        @inlinable
        public func makeIterator() -> IndexingIterator<[Element]> {
            (elements ?? []).makeIterator()
        }
    }
}

extension Graph.Sequential where Payload: Graph.Adjacency, Payload.Tag == Tag {
    /// Returns a topological ordering of nodes reachable from the given roots.
    ///
    /// The returned sequence iterates nodes in an order where each node appears
    /// before any nodes it references. If the graph contains cycles, the sequence
    /// will be empty and `hasCycles` will be true.
    ///
    /// - Parameter roots: The nodes to start from.
    /// - Returns: A topological ordering, or an empty sequence if cycles exist.
    @inlinable
    public func topological(
        from roots: some Sequence<Graph.Node<Tag>>
    ) -> Graph.Traversal.Topological<Tag, Payload> {
        Graph.Traversal.Topological(storage: storage, roots: roots)
    }

    /// Returns a topological ordering of nodes reachable from a single root.
    ///
    /// - Parameter root: The node to start from.
    /// - Returns: A topological ordering, or an empty sequence if cycles exist.
    @inlinable
    public func topological(
        from root: Graph.Node<Tag>
    ) -> Graph.Traversal.Topological<Tag, Payload> {
        topological(from: CollectionOfOne(root))
    }

    /// Returns a topological ordering of all nodes in the graph.
    ///
    /// - Returns: A topological ordering, or an empty sequence if cycles exist.
    @inlinable
    public func topological() -> Graph.Traversal.Topological<Tag, Payload> {
        topological(from: nodes)
    }
}
