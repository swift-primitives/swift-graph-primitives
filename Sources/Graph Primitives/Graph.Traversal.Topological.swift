public import Identity_Primitives
public import Stack_Primitives
public import Bit_Primitives

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
    public struct Topological<Tag, Payload, Adjacent: Sequence<Graph.Node<Tag>>>: Sequence {
        public typealias Element = (node: Graph.Node<Tag>, payload: Payload)

        @usableFromInline
        let elements: [(node: Graph.Node<Tag>, payload: Payload)]?

        @usableFromInline
        init(
            storage: [Payload],
            roots: some Sequence<Graph.Node<Tag>>,
            extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
        ) {
            self.elements = Self.computeOrder(storage: storage, roots: roots, extract: extract)
        }

        @usableFromInline
        static func computeOrder(
            storage: [Payload],
            roots: some Sequence<Graph.Node<Tag>>,
            extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
        ) -> [Element]? {
            let count = storage.count
            guard count > 0 else { return [] }

            // Bit-packed state: O(1) lookup by node.rawValue with 8x memory savings
            var visited = try! Bit.Array(count: count)
            var visiting = try! Bit.Array(count: count)
            var result: [Element] = []
            result.reserveCapacity(count)

            // Stack uses two phases: true = entering, false = leaving
            var stack = Stack<(node: Graph.Node<Tag>, entering: Bool)>()

            for root in roots {
                let rootIndex = root.rawValue
                if visited[rootIndex] { continue }

                stack.push((root, true))

                while let (node, entering) = stack.pop() {
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
                        stack.push((node, false))

                        // Push adjacents to visit
                        let payload = storage[nodeIndex]
                        for adjacent in extract.adjacent(payload) {
                            let adjIndex = adjacent.rawValue
                            if !visited[adjIndex] && !visiting[adjIndex] {
                                stack.push((adjacent, true))
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
