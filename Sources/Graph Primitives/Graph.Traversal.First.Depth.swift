public import Identity_Primitives
public import Stack_Primitives
public import Bit_Primitives
public import Array_Primitives

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
    public struct Depth<Tag, Payload, Adjacent: Swift.Sequence<Graph.Node<Tag>>>: Swift.Sequence, IteratorProtocol {
        public typealias Element = (node: Graph.Node<Tag>, payload: Payload)

        @usableFromInline
        let storage: [Payload]

        @usableFromInline
        let extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>

        @usableFromInline
        var stack: Stack<Graph.Node<Tag>>

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
            self.stack = Stack(roots)
            self.visited = try! Array<Bit>.Packed(count: storage.count)
        }

        @inlinable
        public mutating func next() -> Element? {
            while let node = stack.pop() {
                let idx = Bit.Index(node.position)
                guard !visited[idx] else { continue }
                visited[idx] = true

                let payload = storage[node.position.rawValue]

                for adjacent in extract.adjacent(payload) {
                    let adjIdx = Bit.Index(adjacent.position)
                    if !visited[adjIdx] {
                        stack.push(adjacent)
                    }
                }

                return (node, payload)
            }
            return nil
        }
    }
}
