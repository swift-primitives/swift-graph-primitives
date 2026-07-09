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
