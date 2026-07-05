public import Array_Primitives
// Hoisted carrier spelled directly ([DS-025]/[DS-028]); not surfaced through the umbrella  import.
public import Array_Primitive
public import Bit_Vector_Primitives
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives
public import Buffer_Ring_Primitive
public import Column_Primitives
internal import Iterator_Chunk_Primitives
public import Queue_Primitives
// Hoisted carrier spelled directly ([DS-025]/[DS-028]); not surfaced through the umbrella  import.
public import Queue_Primitive
public import Ownership_Shared_Primitive
public import Tagged_Collection_Primitives
public import Tagged_Primitives
import Vector_Primitives

extension Graph.Traversal.First {
    /// Breadth-first traversal over a graph.
    ///
    /// Visits nodes in breadth-first order starting from the specified roots.
    /// Each node is visited at most once, even if reachable from multiple paths.
    @frozen
    public struct Breadth<Tag: ~Copyable & ~Escapable, Payload, Adjacent: Swift.Sequence<Graph.Node<Tag>>>: ~Copyable, Iterator.Chunk.`Protocol` {
        public typealias Element = (node: Graph.Node<Tag>, payload: Payload)
        public typealias Failure = Never

        @usableFromInline
        let storage: Tagged<Tag, Array<Payload>.Shared>

        @usableFromInline
        let extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>

        @usableFromInline
        var queue: __Queue<Column.Ring<Graph.Node<Tag>>>

        @usableFromInline
        var visited: Bit.Vector

        @usableFromInline
        var _element: Element? = nil

        @usableFromInline
        init(
            storage: Tagged<Tag, Array<Payload>.Shared>,
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
        public mutating func next(maximumCount: some Carrier.`Protocol`<Cardinal>) -> Swift.Span<Element> {
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
