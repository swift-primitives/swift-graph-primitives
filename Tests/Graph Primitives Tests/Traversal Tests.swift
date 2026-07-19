import Graph_Primitives_Test_Support
import Testing

private enum TestTag {}

private struct TestPayload: Sendable {
    let name: String
    let successors: [Graph.Node<TestTag>]
}

extension TestPayload {
    /// Extract for TestPayload adjacency.
    static var extract: Graph.Adjacency.Extract<TestPayload, TestTag, [Graph.Node<TestTag>]> {
        Graph.Adjacency.Extract { $0.successors }
    }
}

// MARK: - Test Graph Builder

private func buildDiamondGraph() -> (
    graph: Graph.Sequential<TestTag, TestPayload>,
    a: Graph.Node<TestTag>,
    b: Graph.Node<TestTag>,
    c: Graph.Node<TestTag>,
    d: Graph.Node<TestTag>
) {
    var builder = Graph.Sequential<TestTag, TestPayload>.Builder()

    // Diamond: A -> B, A -> C, B -> D, C -> D
    let d = builder.allocate(TestPayload(name: "D", successors: []))
    let b = builder.allocate(TestPayload(name: "B", successors: [d]))
    let c = builder.allocate(TestPayload(name: "C", successors: [d]))
    let a = builder.allocate(TestPayload(name: "A", successors: [b, c]))

    return (builder.build(), a, b, c, d)
}

private func buildLinearGraph() -> (
    graph: Graph.Sequential<TestTag, TestPayload>,
    a: Graph.Node<TestTag>,
    b: Graph.Node<TestTag>,
    c: Graph.Node<TestTag>
) {
    var builder = Graph.Sequential<TestTag, TestPayload>.Builder()

    // Linear: A -> B -> C
    let c = builder.allocate(TestPayload(name: "C", successors: []))
    let b = builder.allocate(TestPayload(name: "B", successors: [c]))
    let a = builder.allocate(TestPayload(name: "A", successors: [b]))

    return (builder.build(), a, b, c)
}

// MARK: - Chunk-path (`next(maximumCount:)`) fixtures

/// A payload with NO Array/String/class-reference field: every field is a
/// plain fixed-width integer, so the type has no extra inhabitants and
/// `Optional<Element>` cannot borrow spare bits from it. This maximizes the
/// chance of exposing a layout mismatch between `Element` and
/// `Optional<Element>` (F-002's chunk iterators used to reinterpret a
/// pointer into `Optional<Element>` storage as `Element`). Adjacency is
/// supplied via a captured dictionary — not a stored `Array` field — so the
/// payload itself stays free of extra inhabitants.
private struct ChunkProbePayload: Sendable {
    var a: UInt64
    var b: UInt64
    var id: Int
}

private func buildChunkProbeGraph() -> (
    graph: Graph.Sequential<TestTag, ChunkProbePayload>,
    extract: Graph.Adjacency.Extract<ChunkProbePayload, TestTag, [Graph.Node<TestTag>]>,
    a: Graph.Node<TestTag>,
    b: Graph.Node<TestTag>,
    c: Graph.Node<TestTag>
) {
    var builder = Graph.Sequential<TestTag, ChunkProbePayload>.Builder()

    // Diamond-ish: A -> B, A -> C, B -> C
    let c = builder.allocate(ChunkProbePayload(a: 0xCCCC_CCCC_CCCC_CCCC, b: 0x3333_3333_3333_3333, id: 2))
    let b = builder.allocate(ChunkProbePayload(a: 0xBBBB_BBBB_BBBB_BBBB, b: 0x2222_2222_2222_2222, id: 1))
    let a = builder.allocate(ChunkProbePayload(a: 0xAAAA_AAAA_AAAA_AAAA, b: 0x1111_1111_1111_1111, id: 0))

    let graph = builder.build()
    let adjacency: [Int: [Graph.Node<TestTag>]] = [0: [b, c], 1: [c], 2: []]
    let extract = Graph.Adjacency.Extract<ChunkProbePayload, TestTag, [Graph.Node<TestTag>]> {
        adjacency[$0.id] ?? []
    }
    return (graph, extract, a, b, c)
}

// MARK: - Depth-First Tests

@Suite
struct `Graph Traversal First Depth Tests` {
    @Test
    func `DFS on linear graph`() {
        let (graph, a, _, _) = buildLinearGraph()

        var iter = graph.traverse.first(using: TestPayload.extract).depth(from: a)
        var visited: [String] = []
        while let element = iter.next() {
            visited.append(element.payload.name)
        }
        #expect(visited == ["A", "B", "C"])
    }

    @Test
    func `DFS on diamond graph visits each node once`() {
        let (graph, a, _, _, _) = buildDiamondGraph()

        var iter = graph.traverse.first(using: TestPayload.extract).depth(from: a)
        var visited: [String] = []
        while let element = iter.next() {
            visited.append(element.payload.name)
        }

        // D should appear exactly once despite being reachable via B and C
        #expect(visited.count == 4)
        #expect(visited.first == "A")
        #expect(visited.contains("B"))
        #expect(visited.contains("C"))
        #expect(visited.contains("D"))
    }

    @Test
    func `DFS from multiple roots`() {
        let (graph, _, b, c, _) = buildDiamondGraph()

        var iter = graph.traverse.first(using: TestPayload.extract).depth(from: [b, c])
        var visited: [String] = []
        while let element = iter.next() {
            visited.append(element.payload.name)
        }

        // Should visit B, C, D (D once even though reachable from both)
        #expect(visited.count == 3)
        #expect(visited.contains("B"))
        #expect(visited.contains("C"))
        #expect(visited.contains("D"))
    }

    @Test
    func `DFS on empty roots`() {
        let (graph, _, _, _) = buildLinearGraph()

        var iter = graph.traverse.first(using: TestPayload.extract).depth(from: [] as [Graph.Node<TestTag>])
        var hasElements = false
        while iter.next() != nil { hasElements = true }
        #expect(!hasElements)
    }

    // [F-002] `next(maximumCount:)` used to hand out a `Span<Element>` built
    // from a pointer into `Optional<Element>` storage, reinterpreted via
    // `assumingMemoryBound(to: Element.self)` — a type-pun across two types
    // that are not guaranteed to share layout (verified: for
    // `ChunkProbePayload`, `MemoryLayout<Element>.size` and
    // `MemoryLayout<Element?>.size` genuinely differ on this toolchain), and
    // a pointer escaped past the `withUnsafeMutablePointer` closure that
    // produced it. This drives the chunked path end to end and cross-checks
    // it, field by field, against the scalar `next()` path.
    @Test
    func `Chunked next(maximumCount:) matches scalar next() across full traversal`() {
        let (graph, extract, a, _, _) = buildChunkProbeGraph()

        var reference: [(node: Graph.Node<TestTag>, a: UInt64, b: UInt64, id: Int)] = []
        var refIter = graph.traverse.first(using: extract).depth(from: a)
        while let element = refIter.next() {
            reference.append((element.node, element.payload.a, element.payload.b, element.payload.id))
        }

        var chunked: [(node: Graph.Node<TestTag>, a: UInt64, b: UInt64, id: Int)] = []
        var chunkIter = graph.traverse.first(using: extract).depth(from: a)
        while true {
            let span = chunkIter.next(maximumCount: Cardinal(UInt(1)))
            if span.isEmpty { break }
            let element = span[0]
            chunked.append((element.node, element.payload.a, element.payload.b, element.payload.id))
        }

        #expect(chunked.count == 3)
        #expect(chunked.count == reference.count)
        for (lhs, rhs) in zip(chunked, reference) {
            #expect(lhs.node == rhs.node)
            #expect(lhs.a == rhs.a)
            #expect(lhs.b == rhs.b)
            #expect(lhs.id == rhs.id)
        }
    }

    @Test
    func `Chunked next(maximumCount: 0) yields an empty span without consuming`() {
        let (graph, extract, a, _, _) = buildChunkProbeGraph()

        var iter = graph.traverse.first(using: extract).depth(from: a)
        // `Span<Element>` is `~Escapable`; #expect's autoclosure cannot
        // capture it directly, so bind the plain values first (same
        // constraint noted for `Set<S>.Ordered` in Analysis Tests.swift).
        let zeroSpanIsEmpty = iter.next(maximumCount: Cardinal(UInt(0))).isEmpty
        #expect(zeroSpanIsEmpty)

        // The iterator must still be positioned at the first element.
        let span = iter.next(maximumCount: Cardinal(UInt(1)))
        let count = span.count
        let firstNode = span[0].node
        #expect(count == 1)
        #expect(firstNode == a)
    }
}

// MARK: - Breadth-First Tests

@Suite
struct `Graph Traversal First Breadth Tests` {
    @Test
    func `BFS on linear graph`() {
        let (graph, a, _, _) = buildLinearGraph()

        var iter = graph.traverse.first(using: TestPayload.extract).breadth(from: a)
        var visited: [String] = []
        while let element = iter.next() {
            visited.append(element.payload.name)
        }
        #expect(visited == ["A", "B", "C"])
    }

    @Test
    func `BFS on diamond graph visits each node once`() {
        let (graph, a, _, _, _) = buildDiamondGraph()

        var iter = graph.traverse.first(using: TestPayload.extract).breadth(from: a)
        var visited: [String] = []
        while let element = iter.next() {
            visited.append(element.payload.name)
        }

        // Should visit in level order: A, then B and C, then D
        #expect(visited.count == 4)
        #expect(visited.first == "A")
        #expect(visited.last == "D")
    }

    @Test
    func `BFS visits in level order`() {
        let (graph, a, _, _, _) = buildDiamondGraph()

        var iter = graph.traverse.first(using: TestPayload.extract).breadth(from: a)
        var visited: [String] = []
        while let element = iter.next() {
            visited.append(element.payload.name)
        }

        // A is at level 0, B and C at level 1, D at level 2
        let aIndex = visited.firstIndex(of: "A")!
        let bIndex = visited.firstIndex(of: "B")!
        let cIndex = visited.firstIndex(of: "C")!
        let dIndex = visited.firstIndex(of: "D")!

        #expect(aIndex < bIndex)
        #expect(aIndex < cIndex)
        #expect(bIndex < dIndex)
        #expect(cIndex < dIndex)
    }

    // [F-002] Same hazard as the DFS case above (`Graph.Traversal.First.Breadth`
    // duplicates the identical unsound pattern) — cross-check the chunked path
    // against the scalar path field by field.
    @Test
    func `Chunked next(maximumCount:) matches scalar next() across full traversal`() {
        let (graph, extract, a, _, _) = buildChunkProbeGraph()

        var reference: [(node: Graph.Node<TestTag>, a: UInt64, b: UInt64, id: Int)] = []
        var refIter = graph.traverse.first(using: extract).breadth(from: a)
        while let element = refIter.next() {
            reference.append((element.node, element.payload.a, element.payload.b, element.payload.id))
        }

        var chunked: [(node: Graph.Node<TestTag>, a: UInt64, b: UInt64, id: Int)] = []
        var chunkIter = graph.traverse.first(using: extract).breadth(from: a)
        while true {
            let span = chunkIter.next(maximumCount: Cardinal(UInt(1)))
            if span.isEmpty { break }
            let element = span[0]
            chunked.append((element.node, element.payload.a, element.payload.b, element.payload.id))
        }

        #expect(chunked.count == 3)
        #expect(chunked.count == reference.count)
        for (lhs, rhs) in zip(chunked, reference) {
            #expect(lhs.node == rhs.node)
            #expect(lhs.a == rhs.a)
            #expect(lhs.b == rhs.b)
            #expect(lhs.id == rhs.id)
        }
    }

    @Test
    func `Chunked next(maximumCount: 0) yields an empty span without consuming`() {
        let (graph, extract, a, _, _) = buildChunkProbeGraph()

        var iter = graph.traverse.first(using: extract).breadth(from: a)
        // `Span<Element>` is `~Escapable`; #expect's autoclosure cannot
        // capture it directly, so bind the plain values first (same
        // constraint noted for `Set<S>.Ordered` in Analysis Tests.swift).
        let zeroSpanIsEmpty = iter.next(maximumCount: Cardinal(UInt(0))).isEmpty
        #expect(zeroSpanIsEmpty)

        let span = iter.next(maximumCount: Cardinal(UInt(1)))
        let count = span.count
        let firstNode = span[0].node
        #expect(count == 1)
        #expect(firstNode == a)
    }
}

// MARK: - Topological Tests

@Suite
struct `Graph Traversal Topological Tests` {
    @Test
    func `Topological order on DAG`() {
        let (graph, a, b, c, d) = buildDiamondGraph()

        let order = graph.traverse.topological(from: a, using: TestPayload.extract)
        #expect(!order.hasCycles)

        let nodes = order.map { $0.node }

        // A must come before B and C
        // B and C must come before D
        let aIndex = nodes.firstIndex(of: a)!
        let bIndex = nodes.firstIndex(of: b)!
        let cIndex = nodes.firstIndex(of: c)!
        let dIndex = nodes.firstIndex(of: d)!

        #expect(aIndex < bIndex)
        #expect(aIndex < cIndex)
        #expect(bIndex < dIndex)
        #expect(cIndex < dIndex)
    }

    @Test
    func `Topological order detects cycles`() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()

        // A -> B -> C -> A (cycle)
        let a = builder.allocate(TestPayload(name: "A", successors: []))
        let b = builder.allocate(TestPayload(name: "B", successors: []))
        let c = builder.allocate(TestPayload(name: "C", successors: [a]))
        builder[a] = TestPayload(name: "A", successors: [b])
        builder[b] = TestPayload(name: "B", successors: [c])

        let cyclicGraph = builder.build()

        let order = cyclicGraph.traverse.topological(from: a, using: TestPayload.extract)
        #expect(order.hasCycles)
    }

    @Test
    func `Topological order on linear graph`() {
        let (graph, a, _, _) = buildLinearGraph()

        let order = graph.traverse.topological(from: a, using: TestPayload.extract)
        #expect(!order.hasCycles)

        let names = order.map { $0.payload.name }
        #expect(names == ["A", "B", "C"])
    }
}
