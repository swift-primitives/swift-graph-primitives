public import Identity_Primitives
public import Bit_Primitives
public import Array_Primitives

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
    public struct Breadth<Tag, Payload, Adjacent: Sequence<Graph.Node<Tag>>>: Sequence, IteratorProtocol {
        public typealias Element = (node: Graph.Node<Tag>, payload: Payload)

        @usableFromInline
        let storage: [Payload]

        @usableFromInline
        let extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>

        @usableFromInline
        var queue: [Graph.Node<Tag>]

        @usableFromInline
        var queueIndex: Int

        @usableFromInline
        var visited: Bit.Array

        @usableFromInline
        init(
            storage: [Payload],
            roots: some Sequence<Graph.Node<Tag>>,
            extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
        ) {
            self.storage = storage
            self.extract = extract
            self.queue = []
            self.queueIndex = 0
            self.visited = try! Bit.Array(count: storage.count)

            for root in roots {
                if !visited[root.rawValue] {
                    visited[root.rawValue] = true
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

            for adjacent in extract.adjacent(payload) {
                if !visited[adjacent.rawValue] {
                    visited[adjacent.rawValue] = true
                    queue.append(adjacent)
                }
            }

            return (node, payload)
        }
    }
}
