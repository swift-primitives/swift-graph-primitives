public import Tagged_Primitives
import Stack_Primitives
import Bit_Vector_Primitives
public import Array_Primitives

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
    public struct Topological<Tag, Payload, Adjacent: Swift.Sequence<Graph.Node<Tag>>>: Swift.Sequence {
        public typealias Element = (node: Graph.Node<Tag>, payload: Payload)

        @usableFromInline
        let elements: [(node: Graph.Node<Tag>, payload: Payload)]?

        @usableFromInline
        init(
            storage: Array<Payload>.Indexed<Tag>,
            roots: some Swift.Sequence<Graph.Node<Tag>>,
            extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
        ) {
            self.elements = Self.computeOrder(storage: storage, roots: roots, extract: extract)
        }

        @usableFromInline
        static func computeOrder(
            storage: Array<Payload>.Indexed<Tag>,
            roots: some Swift.Sequence<Graph.Node<Tag>>,
            extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
        ) -> [Element]? {
            let count = storage.count
            guard count > .zero else { return [] }

            // Bit-packed state: O(1) lookup by node position with 8x memory savings
            let visited = Bit.Vector(capacity: count.retag(Bit.self))
            let visiting = Bit.Vector(capacity: count.retag(Bit.self))
            var result: [Element] = []
            result.reserveCapacity(Int(bitPattern: count.underlying.rawValue))

            // Stack uses two phases: true = entering, false = leaving
            var stack = Stack<(node: Graph.Node<Tag>, entering: Bool)>()

            for root in roots {
                let rootIdx = root.retag(Bit.self)
                if visited[rootIdx] { continue }

                stack.push((root, true))

                while let (node, entering) = stack.pop() {
                    let nodeIdx = node.retag(Bit.self)

                    if entering {
                        // Entering: check state and push adjacents
                        if visited[nodeIdx] { continue }
                        if visiting[nodeIdx] {
                            // Cycle detected: node is on current DFS path
                            return nil
                        }

                        visiting[nodeIdx] = true

                        // Push leave action first (will be processed after all adjacents)
                        stack.push((node, false))

                        // Push adjacents to visit
                        let payload = storage[node]
                        for adjacent in extract.adjacent(payload) {
                            let adjIdx = adjacent.retag(Bit.self)
                            if !visited[adjIdx] && !visiting[adjIdx] {
                                stack.push((adjacent, true))
                            } else if visiting[adjIdx] {
                                // Cycle detected
                                return nil
                            }
                        }
                    } else {
                        // Leaving: mark visited and record in result
                        visiting[nodeIdx] = false
                        visited[nodeIdx] = true
                        result.append((node, storage[node]))
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
