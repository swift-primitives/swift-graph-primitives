import Testing
@testable import Graph_Primitives

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

@Suite("Graph.Traversal.First.Depth")
struct DepthFirstTests {
    @Test("DFS on linear graph")
    func linearGraph() {
        let (graph, a, _, _) = buildLinearGraph()

        let visited = graph.traverse.first(using: TestPayload.extract).depth(from: a).map { $0.payload.name }
        #expect(visited == ["A", "B", "C"])
    }

    @Test("DFS on diamond graph visits each node once")
    func diamondGraph() {
        let (graph, a, _, _, _) = buildDiamondGraph()

        let visited = graph.traverse.first(using: TestPayload.extract).depth(from: a).map { $0.payload.name }

        // D should appear exactly once despite being reachable via B and C
        #expect(visited.count == 4)
        #expect(visited.first == "A")
        #expect(visited.contains("B"))
        #expect(visited.contains("C"))
        #expect(visited.contains("D"))
    }

    @Test("DFS from multiple roots")
    func multipleRoots() {
        let (graph, _, b, c, _) = buildDiamondGraph()

        let visited = graph.traverse.first(using: TestPayload.extract).depth(from: [b, c]).map { $0.payload.name }

        // Should visit B, C, D (D once even though reachable from both)
        #expect(visited.count == 3)
        #expect(visited.contains("B"))
        #expect(visited.contains("C"))
        #expect(visited.contains("D"))
    }

    @Test("DFS on empty roots")
    func emptyRoots() {
        let (graph, _, _, _) = buildLinearGraph()

        let visited = Array(graph.traverse.first(using: TestPayload.extract).depth(from: [] as [Graph.Node<TestTag>]))
        #expect(visited.isEmpty)
    }
}

// MARK: - Breadth-First Tests

@Suite("Graph.Traversal.First.Breadth")
struct BreadthFirstTests {
    @Test("BFS on linear graph")
    func linearGraph() {
        let (graph, a, _, _) = buildLinearGraph()

        let visited = graph.traverse.first(using: TestPayload.extract).breadth(from: a).map { $0.payload.name }
        #expect(visited == ["A", "B", "C"])
    }

    @Test("BFS on diamond graph visits each node once")
    func diamondGraph() {
        let (graph, a, _, _, _) = buildDiamondGraph()

        let visited = graph.traverse.first(using: TestPayload.extract).breadth(from: a).map { $0.payload.name }

        // Should visit in level order: A, then B and C, then D
        #expect(visited.count == 4)
        #expect(visited.first == "A")
        #expect(visited.last == "D")
    }

    @Test("BFS visits in level order")
    func levelOrder() {
        let (graph, a, _, _, _) = buildDiamondGraph()

        let visited = graph.traverse.first(using: TestPayload.extract).breadth(from: a).map { $0.payload.name }

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

@Suite("Graph.Traversal.Topological")
struct TopologicalTests {
    @Test("Topological order on DAG")
    func dagTopologicalOrder() {
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

    @Test("Topological order detects cycles")
    func cycleDetection() {
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

    @Test("Topological order on linear graph")
    func linearTopologicalOrder() {
        let (graph, a, _, _) = buildLinearGraph()

        let order = graph.traverse.topological(from: a, using: TestPayload.extract)
        #expect(!order.hasCycles)

        let names = order.map { $0.payload.name }
        #expect(names == ["A", "B", "C"])
    }
}
