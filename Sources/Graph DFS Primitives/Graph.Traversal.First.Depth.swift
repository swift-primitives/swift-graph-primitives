public import Array_Primitives
public import Bit_Vector_Primitives
internal import Iterator_Chunk_Primitives
public import Stack_Primitives
public import Tagged_Primitives
public import Tagged_Collection_Primitives
public import Vector_Primitives

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
    public struct Depth<Tag: ~Copyable & ~Escapable, Payload, Adjacent: Swift.Sequence<Graph.Node<Tag>>>: ~Copyable, Iterator.Chunk.`Protocol` {
        public typealias Element = (node: Graph.Node<Tag>, payload: Payload)
        public typealias Failure = Never

        @usableFromInline
        let storage: Tagged<Tag, Array<Payload>>

        @usableFromInline
        let extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>

        @usableFromInline
        var stack: Stack<Graph.Node<Tag>>

        @usableFromInline
        var visited: Bit.Vector

        @usableFromInline
        var _element: Element? = nil

        @usableFromInline
        init(
            storage: Tagged<Tag, Array<Payload>>,
            roots: some Swift.Sequence<Graph.Node<Tag>>,
            extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
        ) {
            self.storage = storage
            self.extract = extract
            self.stack = Stack()
            self.visited = Bit.Vector(capacity: storage.count.retag(Bit.self))

            for root in roots {
                stack.push(root)
            }
        }

        @_lifetime(&self)
        @inlinable
        public mutating func next(maximumCount: some Carrier.`Protocol`<Cardinal>) -> Span<Element> {
            let ptr = unsafe withUnsafeMutablePointer(to: &_element) { p in
                unsafe UnsafePointer<Element>(
                    unsafe UnsafeRawPointer(p).assumingMemoryBound(to: Element.self)
                )
            }
            guard maximumCount.underlying > .zero else {
                let span = unsafe Span(_unsafeStart: ptr, count: 0)
                return unsafe _overrideLifetime(span, mutating: &self)
            }
            guard let value = next() else {
                let span = unsafe Span(_unsafeStart: ptr, count: 0)
                return unsafe _overrideLifetime(span, mutating: &self)
            }
            _element = value
            let span = unsafe Span(_unsafeStart: ptr, count: 1)
            return unsafe _overrideLifetime(span, mutating: &self)
        }

        @inlinable
        public mutating func next() -> Element? {
            while let node = stack.pop() {
                let idx = node.retag(Bit.self)
                guard !visited[idx] else { continue }
                visited[idx] = true

                let payload = storage[node]

                for adjacent in extract.adjacent(payload) {
                    let adjIdx = adjacent.retag(Bit.self)
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
