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

// MARK: - Reachability Tests

@Suite("Graph.Reachability")
struct ReachabilityTests {
    @Test("Reachable from single root in DAG")
    func reachableFromRoot() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()

        // Diamond: A -> B, A -> C, B -> D, C -> D
        let d = builder.allocate(TestPayload(name: "D", successors: []))
        let b = builder.allocate(TestPayload(name: "B", successors: [d]))
        let c = builder.allocate(TestPayload(name: "C", successors: [d]))
        let a = builder.allocate(TestPayload(name: "A", successors: [b, c]))

        let graph = builder.build()

        let reachable = graph.analyze(using: TestPayload.extract).reachable(from: a)
        #expect(reachable.count == 4)
        #expect(reachable.contains(a))
        #expect(reachable.contains(b))
        #expect(reachable.contains(c))
        #expect(reachable.contains(d))
    }

    @Test("Reachable from middle node")
    func reachableFromMiddle() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()

        let d = builder.allocate(TestPayload(name: "D", successors: []))
        let b = builder.allocate(TestPayload(name: "B", successors: [d]))
        let c = builder.allocate(TestPayload(name: "C", successors: [d]))
        let a = builder.allocate(TestPayload(name: "A", successors: [b, c]))

        let graph = builder.build()

        let reachable = graph.analyze(using: TestPayload.extract).reachable(from: b)
        #expect(reachable.count == 2)
        #expect(reachable.contains(b))
        #expect(reachable.contains(d))
        #expect(!reachable.contains(a))
        #expect(!reachable.contains(c))
    }

    @Test("Reachable from multiple roots")
    func reachableFromMultipleRoots() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()

        // Two disconnected chains: A -> B and C -> D
        let b = builder.allocate(TestPayload(name: "B", successors: []))
        let a = builder.allocate(TestPayload(name: "A", successors: [b]))
        let d = builder.allocate(TestPayload(name: "D", successors: []))
        let c = builder.allocate(TestPayload(name: "C", successors: [d]))

        let graph = builder.build()

        let reachable = graph.analyze(using: TestPayload.extract).reachable(from: [a, c])
        #expect(reachable.count == 4)
    }

    @Test("Reachable from leaf node")
    func reachableFromLeaf() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()

        let c = builder.allocate(TestPayload(name: "C", successors: []))
        let b = builder.allocate(TestPayload(name: "B", successors: [c]))
        let a = builder.allocate(TestPayload(name: "A", successors: [b]))

        let graph = builder.build()

        let reachable = graph.analyze(using: TestPayload.extract).reachable(from: c)
        #expect(reachable.count == 1)
        #expect(reachable.contains(c))
    }
}

// MARK: - Cycle Detection Tests

@Suite("Graph.CycleDetection")
struct CycleDetectionTests {
    @Test("No cycles in DAG")
    func noCyclesInDAG() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()

        let c = builder.allocate(TestPayload(name: "C", successors: []))
        let b = builder.allocate(TestPayload(name: "B", successors: [c]))
        let a = builder.allocate(TestPayload(name: "A", successors: [b]))

        let graph = builder.build()

        #expect(!graph.analyze(using: TestPayload.extract).hasCycles(from: a))
        #expect(!graph.analyze(using: TestPayload.extract).hasCycles())
    }

    @Test("Self-loop detected")
    func selfLoopDetected() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()

        let a = builder.allocate(TestPayload(name: "A", successors: []))
        builder[a] = TestPayload(name: "A", successors: [a])

        let graph = builder.build()

        #expect(graph.analyze(using: TestPayload.extract).hasCycles(from: a))
    }

    @Test("Cycle in graph detected")
    func cycleDetected() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()

        // A -> B -> C -> A
        let a = builder.allocate(TestPayload(name: "A", successors: []))
        let b = builder.allocate(TestPayload(name: "B", successors: []))
        let c = builder.allocate(TestPayload(name: "C", successors: [a]))
        builder[a] = TestPayload(name: "A", successors: [b])
        builder[b] = TestPayload(name: "B", successors: [c])

        let graph = builder.build()

        #expect(graph.analyze(using: TestPayload.extract).hasCycles(from: a))
    }
}

// MARK: - SCC Tests

@Suite("Graph.StronglyConnectedComponents")
struct SCCTests {
    @Test("SCC in DAG (each node is its own SCC)")
    func sccInDAG() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()

        let c = builder.allocate(TestPayload(name: "C", successors: []))
        let b = builder.allocate(TestPayload(name: "B", successors: [c]))
        let a = builder.allocate(TestPayload(name: "A", successors: [b]))

        let graph = builder.build()

        let sccs = graph.analyze(using: TestPayload.extract).scc(from: a)

        // Each node is its own SCC in a DAG
        #expect(sccs.count == 3)
        #expect(sccs.allSatisfy { $0.count == 1 })
    }

    @Test("SCC with cycle")
    func sccWithCycle() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()

        // A -> B -> C -> A (single SCC containing all three)
        let a = builder.allocate(TestPayload(name: "A", successors: []))
        let b = builder.allocate(TestPayload(name: "B", successors: []))
        let c = builder.allocate(TestPayload(name: "C", successors: [a]))
        builder[a] = TestPayload(name: "A", successors: [b])
        builder[b] = TestPayload(name: "B", successors: [c])

        let graph = builder.build()

        let sccs = graph.analyze(using: TestPayload.extract).scc(from: a)

        // All three nodes form one SCC
        #expect(sccs.count == 1)
        #expect(sccs[0].count == 3)
    }

    @Test("Multiple SCCs")
    func multipleSCCs() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()

        // Two cycles connected: (A <-> B) -> (C <-> D)
        let a = builder.allocate(TestPayload(name: "A", successors: []))
        let b = builder.allocate(TestPayload(name: "B", successors: [a]))
        let c = builder.allocate(TestPayload(name: "C", successors: []))
        let d = builder.allocate(TestPayload(name: "D", successors: [c]))

        builder[a] = TestPayload(name: "A", successors: [b, c])
        builder[c] = TestPayload(name: "C", successors: [d])

        let graph = builder.build()

        let sccs = graph.analyze(using: TestPayload.extract).scc(from: a)

        // Two SCCs: {A, B} and {C, D}
        #expect(sccs.count == 2)
        #expect(sccs.allSatisfy { $0.count == 2 })
    }

    @Test("Self-loop is SCC")
    func selfLoopSCC() {
        var builder = Graph.Sequential<TestTag, TestPayload>.Builder()

        let a = builder.allocate(TestPayload(name: "A", successors: []))
        builder[a] = TestPayload(name: "A", successors: [a])

        let graph = builder.build()

        let sccs = graph.analyze(using: TestPayload.extract).scc(from: a)

        #expect(sccs.count == 1)
        #expect(sccs[0] == [a])
    }
}
