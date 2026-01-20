import Testing
@testable import Graph_Primitives

// MARK: - Test Types

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

    /// Default value for TestPayload holes.
    static var defaultValue: Graph.Default.Value<TestPayload> {
        Graph.Default.Value(TestPayload(name: "hole", successors: []))
    }
}

// MARK: - Sequential Tests

@Suite("Graph.Sequential")
struct SequentialTests {
    @Test("Empty graph has zero count")
    func emptyGraph() {
        let builder = Graph.Sequential<TestTag, TestPayload>.Builder()
        let graph = builder.build()

        #expect(graph.count == 0)
        #expect(graph.isEmpty)
    }

    @Test("Single node graph")
    func singleNode() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()
        let node = builder.allocate(TestPayload(name: "A", successors: []))
        let graph = builder.build()

        #expect(graph.count == 1)
        #expect(!graph.isEmpty)
        #expect(graph[node].name == "A")
    }

    @Test("Multiple nodes preserve order")
    func multipleNodes() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()
        let a = builder.allocate(TestPayload(name: "A", successors: []))
        let b = builder.allocate(TestPayload(name: "B", successors: []))
        let c = builder.allocate(TestPayload(name: "C", successors: []))
        let graph = builder.build()

        #expect(graph.count == 3)
        #expect(graph[a].name == "A")
        #expect(graph[b].name == "B")
        #expect(graph[c].name == "C")
    }

    @Test("Nodes iteration")
    func nodesIteration() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()
        _ = builder.allocate(TestPayload(name: "A", successors: []))
        _ = builder.allocate(TestPayload(name: "B", successors: []))
        _ = builder.allocate(TestPayload(name: "C", successors: []))
        let graph = builder.build()

        let names = graph.nodes.map { graph[$0].name }
        #expect(names == ["A", "B", "C"])
    }
}

// MARK: - Builder Tests

@Suite("Graph.Sequential.Builder")
struct BuilderTests {
    @Test("Builder with capacity")
    func builderWithCapacity() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder(capacity: 10)
        _ = builder.allocate(TestPayload(name: "A", successors: []))
        #expect(builder.count == 1)
    }

    @Test("Builder subscript access")
    func builderSubscript() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()
        let node = builder.allocate(TestPayload(name: "A", successors: []))
        #expect(builder[node].name == "A")

        builder[node] = TestPayload(name: "Updated", successors: [])
        #expect(builder[node].name == "Updated")
    }

    @Test("Hole allocation and fill")
    func holeAllocationAndFill() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()
        let hole = builder.allocateHole(using: TestPayload.defaultValue)
        #expect(builder[hole].name == "hole")

        builder.fill(hole, with: TestPayload(name: "Filled", successors: []))
        #expect(builder[hole].name == "Filled")
    }

    @Test("Forward reference via holes")
    func forwardReference() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()

        // Allocate hole for forward reference
        let a = builder.allocateHole(using: TestPayload.defaultValue)
        let b = builder.allocate(TestPayload(name: "B", successors: [a]))

        // Fill the hole with reference to b
        builder.fill(a, with: TestPayload(name: "A", successors: [b]))

        let graph = builder.build()

        #expect(graph[a].name == "A")
        #expect(graph[b].name == "B")
        #expect(graph[a].successors == [b])
        #expect(graph[b].successors == [a])
    }
}
