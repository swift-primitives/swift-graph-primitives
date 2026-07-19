// Hoisted carrier spelled directly ([DS-025]/[DS-028]); not surfaced through the umbrella  import.
public import Array_Primitive
public import Array_Primitives
public import Bit_Vector_Primitives
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives
public import Column_Primitives
internal import Iterator_Chunk_Primitives
public import Ownership_Shared_Primitive
public import Stack_Primitives
public import Tagged_Collection_Primitives
public import Tagged_Primitives
import Vector_Primitives

extension Graph.Traversal.First {
    // WHY: Category D (SP-5) — pointer-backed move-only iterator. `_elementBox`
    // WHY: is `@usableFromInline` (internal, not public); the only public surface
    // WHY: that touches it is `next(maximumCount:)`, which returns a
    // WHY: lifetime-bound `Span` rather than the raw pointer. Per [MEM-SAFE-028]
    // WHY: (the drain-box rule), teardown of the pointer lives in a refcounted
    // WHY: CLASS's `deinit`, not a custom `deinit` on this generic `~Copyable`
    // WHY: struct: on this toolchain a `~Copyable` struct's own synthesized
    // WHY: deinit can be skipped/miscompiled at `-O` for generic-nested shapes
    // WHY: (re-confirmed on 6.3.3; empirically reproduced here too — see F-002
    // WHY: deviation notes in REPORT.md). A `final class`'s ARC-driven deinit is
    // WHY: the unaffected, well-trodden path.
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
    @safe
    @frozen
    public struct Depth<Tag: ~Copyable & ~Escapable, Payload, Adjacent: Swift.Sequence<Graph.Node<Tag>>>: ~Copyable, Iterator.Chunk.`Protocol` {
        /// A node paired with its payload, in depth-first visitation order.
        public typealias Element = (node: Graph.Node<Tag>, payload: Payload)
        /// This iterator never throws.
        public typealias Failure = Never

        /// Owns the single-element scratch storage backing the `Span` returned by `next(maximumCount:)`.
        ///
        /// [F-002] `next(maximumCount:)` used to be built from a pointer into
        /// `var _element: Element? = nil` storage, obtained via
        /// `withUnsafeMutablePointer(to: &_element)` and reinterpreted with
        /// `UnsafeRawPointer(p).assumingMemoryBound(to: Element.self)` — i.e. a
        /// pointer bound to `Optional<Element>` storage, punned as `Element`.
        /// `Optional<Element>` is not guaranteed to share `Element`'s layout (it
        /// does not here: for a `Payload` with no spare bits, `Optional<Element>`
        /// carries a genuine out-of-band discriminator and is wider than
        /// `Element`), so `assumingMemoryBound` was binding memory to a type
        /// other than the type it is actually bound as — undefined behavior
        /// regardless of whether today's ABI happens to keep the read correct.
        /// The pointer was also returned out of the `withUnsafeMutablePointer`
        /// closure and used after the closure had already returned, past the
        /// window the closure's pointer argument is documented valid for.
        ///
        /// The replacement is a dedicated, always-`Element`-bound heap slot:
        /// honestly typed (no reinterpretation). Ownership lives in this
        /// refcounted box (see [MEM-SAFE-028]) rather than directly on `Depth`,
        /// so teardown rides the box's ordinary class `deinit`.
        @safe
        @usableFromInline
        final class _ElementBox {
            @usableFromInline
            let pointer: UnsafeMutablePointer<Element>

            @usableFromInline
            var isInitialized: Bool = false

            @usableFromInline
            init() {
                unsafe pointer = .allocate(capacity: 1)
            }

            deinit {
                if isInitialized {
                    unsafe pointer.deinitialize(count: 1)
                }
                unsafe pointer.deallocate()
            }
        }

        @usableFromInline
        let storage: Tagged<Tag, Array<Payload>.Shared>

        @usableFromInline
        let extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>

        @usableFromInline
        var stack: Stack<Graph.Node<Tag>>

        @usableFromInline
        var visited: Bit.Vector

        @usableFromInline
        let _elementBox: _ElementBox

        @usableFromInline
        init(
            storage: Tagged<Tag, Array<Payload>.Shared>,
            roots: some Swift.Sequence<Graph.Node<Tag>>,
            extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
        ) {
            self.storage = storage
            self.extract = extract
            self.stack = Stack()
            self.visited = Bit.Vector(capacity: storage.count.retag(Bit.self))
            self._elementBox = _ElementBox()

            for root in roots {
                stack.push(root)
            }
        }

        /// Advances by up to `maximumCount` elements, returning them as a span over
        /// internal single-element storage (`Iterator.Chunk` protocol requirement).
        @_lifetime(&self)
        @inlinable
        public mutating func next(maximumCount: some Carrier.`Protocol`<Cardinal>) -> Swift.Span<Element> {
            // Hoisting `_elementBox` and its `.pointer` to locals before the
            // `mark_dependence`-generating `Span` construction below is
            // required, not stylistic: writing `_elementBox.pointer` inline at
            // each use site crashes the Swift 6.3.3 `-O` CopyPropagation SIL
            // pass ("Found outside of lifetime use?! ... load_borrow ...
            // _ElementBox ... Non Consuming User: mark_dependence [nonescaping]
            // ... on ... UnsafeMutablePointer") — a compiler ICE, empirically
            // reproduced while developing this fix. The hoisted-local form
            // compiles clean and has been stress-run repeatedly (10+ release
            // runs, full suite) with no crash.
            let box = _elementBox
            let pointer = unsafe box.pointer
            guard maximumCount.underlying > .zero else {
                let span = unsafe Span(_unsafeStart: pointer, count: 0)
                return unsafe _overrideLifetime(span, mutating: &self)
            }
            guard let value = next() else {
                let span = unsafe Span(_unsafeStart: pointer, count: 0)
                return unsafe _overrideLifetime(span, mutating: &self)
            }
            if box.isInitialized {
                unsafe pointer.pointee = value
            } else {
                unsafe pointer.initialize(to: value)
                box.isInitialized = true
            }
            let span = unsafe Span(_unsafeStart: pointer, count: 1)
            return unsafe _overrideLifetime(span, mutating: &self)
        }

        /// Pops the next unvisited node in depth-first order, pushing its unvisited
        /// adjacents, or returns `nil` when the stack is exhausted.
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
