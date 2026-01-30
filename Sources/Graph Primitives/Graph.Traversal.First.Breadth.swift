public import Identity_Primitives
public import Bit_Primitives
public import Array_Primitives
public import Queue_Primitives

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
    public struct Breadth<Tag, Payload, Adjacent: Swift.Sequence<Graph.Node<Tag>>>: Swift.Sequence, IteratorProtocol {
        public typealias Element = (node: Graph.Node<Tag>, payload: Payload)

        @usableFromInline
        let storage: [Payload]

        @usableFromInline
        let extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>

        @usableFromInline
        var queue: Queue<Graph.Node<Tag>>

        @usableFromInline
        var visited: Array<Bit>.Packed

        @usableFromInline
        init(
            storage: [Payload],
            roots: some Swift.Sequence<Graph.Node<Tag>>,
            extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
        ) {
            self.storage = storage
            self.extract = extract
            self.queue = Queue()
            self.visited = try! Array<Bit>.Packed(count: storage.count)

            for root in roots {
                let idx = Bit.Index(root.position)
                if !visited[idx] {
                    visited[idx] = true
                    queue.enqueue(root)
                }
            }
        }

        @inlinable
        public mutating func next() -> Element? {
            guard let node = queue.dequeue() else { return nil }

            let payload = storage[node.position]

            for adjacent in extract.adjacent(payload) {
                let idx = Bit.Index(adjacent.position)
                if !visited[idx] {
                    visited[idx] = true
                    queue.enqueue(adjacent)
                }
            }

            return (node, payload)
        }
    }
}
