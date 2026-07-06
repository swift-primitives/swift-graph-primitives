import Graph_Primitives_Test_Support
import Testing

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
    @Test
    func `Empty graph has zero count`() {
        let builder = Graph.Sequential<TestTag, TestPayload>.Builder()
        let graph = builder.build()

        #expect(graph.count == 0)
        #expect(graph.isEmpty)
    }

    @Test
    func `Single node graph`() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()
        let node = builder.allocate(TestPayload(name: "A", successors: []))
        let graph = builder.build()

        #expect(graph.count == 1)
        #expect(!graph.isEmpty)
        #expect(graph[node].name == "A")
    }

    @Test
    func `Multiple nodes preserve order`() {
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

    @Test
    func `Nodes iteration`() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()
        _ = builder.allocate(TestPayload(name: "A", successors: []))
        _ = builder.allocate(TestPayload(name: "B", successors: []))
        _ = builder.allocate(TestPayload(name: "C", successors: []))
        let graph = builder.build()

        // Iterate the concrete `Vector.Iterator` (Swift.Sequence). The
        // `Sequenceable.map { … }.collect()` eager-map path instantiates a
        // generic `Sequence.Map<Vector<Tagged>>.Eager` wrapper whose metadata
        // demangling trips the §A9 Tagged-metadata SIGSEGV on Swift 6.3.x; the
        // direct loop sidesteps it and runs on the current toolchain.
        var names: [String] = []
        for node in graph.nodes {
            names.append(graph[node].name)
        }
        #expect(names == ["A", "B", "C"])
    }
}

// MARK: - Builder Tests

@Suite("Graph.Sequential.Builder")
struct BuilderTests {
    @Test
    func `Builder with capacity`() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder(capacity: 10)
        _ = builder.allocate(TestPayload(name: "A", successors: []))
        #expect(builder.count == 1)
    }

    @Test
    func `Builder subscript access`() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()
        let node = builder.allocate(TestPayload(name: "A", successors: []))
        #expect(builder[node].name == "A")

        builder[node] = TestPayload(name: "Updated", successors: [])
        #expect(builder[node].name == "Updated")
    }

    @Test
    func `Hole allocation and fill`() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()
        let hole = builder.allocateHole(using: TestPayload.defaultValue)
        #expect(builder[hole].name == "hole")

        builder.fill(hole, with: TestPayload(name: "Filled", successors: []))
        #expect(builder[hole].name == "Filled")
    }

    @Test
    func `Forward reference via holes`() {
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
