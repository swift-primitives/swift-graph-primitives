public import Identity_Primitives
public import Bit_Vector_Primitives
public import Array_Primitives
public import Queue_Primitives
internal import Sequence_Primitives

extension Graph.Traversal.First {
    /// Breadth-first traversal over a graph.
    ///
    /// Visits nodes in breadth-first order starting from the specified roots.
    /// Each node is visited at most once, even if reachable from multiple paths.
    public struct Breadth<Tag, Payload, Adjacent: Swift.Sequence<Graph.Node<Tag>>>: ~Copyable, Sequence.Iterator.`Protocol` {
        public typealias Element = (node: Graph.Node<Tag>, payload: Payload)

        @usableFromInline
        let storage: Array<Payload>.Indexed<Tag>

        @usableFromInline
        let extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>

        @usableFromInline
        var queue: Queue<Graph.Node<Tag>>

        @usableFromInline
        var visited: Bit.Vector

        @usableFromInline
        var _spanBuffer: [Element] = []

        @usableFromInline
        init(
            storage: Array<Payload>.Indexed<Tag>,
            roots: some Swift.Sequence<Graph.Node<Tag>>,
            extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
        ) {
            self.storage = storage
            self.extract = extract
            self.queue = Queue()
            self.visited = Bit.Vector(capacity: storage.count.retag(Bit.self))

            for root in roots {
                let idx = root.retag(Bit.self)
                if !visited[idx] {
                    visited[idx] = true
                    queue.enqueue(root)
                }
            }
        }

        @_lifetime(&self)
        @inlinable
        public mutating func nextSpan(maximumCount: Cardinal) -> Span<Element> {
            _spanBuffer.removeAll(keepingCapacity: true)
            var remaining = Int(maximumCount.rawValue)
            while remaining > 0 {
                guard let node = queue.dequeue() else { break }

                let payload = storage[node]

                for adjacent in extract.adjacent(payload) {
                    let idx = adjacent.retag(Bit.self)
                    if !visited[idx] {
                        visited[idx] = true
                        queue.enqueue(adjacent)
                    }
                }

                _spanBuffer.append((node, payload))
                remaining -= 1
            }
            return _spanBuffer.span
        }

        @inlinable
        public mutating func next() -> Element? {
            guard let node = queue.dequeue() else { return nil }

            let payload = storage[node]

            for adjacent in extract.adjacent(payload) {
                let idx = adjacent.retag(Bit.self)
                if !visited[idx] {
                    visited[idx] = true
                    queue.enqueue(adjacent)
                }
            }

            return (node, payload)
        }
    }
}
