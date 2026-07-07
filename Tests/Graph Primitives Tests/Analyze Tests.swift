import Graph_Primitives_Test_Support
import Testing

private enum TestTag {}

// MARK: - Dead Nodes Tests

// `.dead(from:)` builds a `Set<Graph.Node>.Ordered` (= `Set<Tagged>.Ordered`),
// whose insert SIGSEGVs on Swift 6.3.x (catalog §A9). Skipped until 6.4+.
@Suite(
    "Graph.Sequential.Analyze.Dead",
    .disabled(if: Toolchain.hasTaggedMetadataSIGSEGV, "§A9 Tagged metadata SIGSEGV in Set<Index>.Ordered.insert; fixed on Swift 6.4+")
)
struct DeadNodesTests {
    @Test
    func `Dead nodes in disconnected graph`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // A -> B,  C, D (C and D disconnected)
        let d = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let c = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()

        // `Set<S>.Ordered` is move-only on the direct column; #expect's autoclosure
        // cannot capture it, so bind copyable results first.
        let dead = graph.analyze.dead(from: [a])

        let hasC = dead.contains(c)
        let hasD = dead.contains(d)
        let hasA = dead.contains(a)
        let hasB = dead.contains(b)
        let count = dead.count
        #expect(hasC)
        #expect(hasD)
        #expect(!hasA)
        #expect(!hasB)
        #expect(count == 2)
    }

    @Test
    func `Dead nodes from all roots is empty`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // A -> B -> C
        let c = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [c]))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()

        let dead = graph.analyze.dead(from: [a])

        let isEmpty = dead.isEmpty
        #expect(isEmpty)
    }

    @Test
    func `Dead nodes from empty roots`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        let c = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [c]))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()

        let dead = graph.analyze.dead(from: [] as [Graph.Node<TestTag>])

        let count = dead.count
        let hasA = dead.contains(a)
        let hasB = dead.contains(b)
        let hasC = dead.contains(c)
        #expect(count == 3)
        #expect(hasA)
        #expect(hasB)
        #expect(hasC)
    }

    @Test
    func `Dead nodes in empty graph`() {
        let graph = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder().build()

        let dead = graph.analyze.dead(from: [] as [Graph.Node<TestTag>])

        let isEmpty = dead.isEmpty
        #expect(isEmpty)
    }

    @Test
    func `Dead nodes from multiple roots`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // A -> B,  C -> D,  E (disconnected)
        let e = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let d = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let c = builder.allocate(Graph.Adjacency.List(adjacent: [d]))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()

        let dead = graph.analyze.dead(from: [a, c])

        let hasE = dead.contains(e)
        let hasA = dead.contains(a)
        let hasB = dead.contains(b)
        let hasC = dead.contains(c)
        let hasD = dead.contains(d)
        let count = dead.count
        #expect(hasE)
        #expect(!hasA)
        #expect(!hasB)
        #expect(!hasC)
        #expect(!hasD)
        #expect(count == 1)
    }
}

// MARK: - Transitive Closure Tests

@Suite("Graph.Sequential.Analyze.TransitiveClosure")
struct TransitiveClosureTests {
    @Test
    func `Transitive closure on diamond DAG has correct edge count`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // Diamond: A -> B, A -> C, B -> D, C -> D
        let d = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [d]))
        let c = builder.allocate(Graph.Adjacency.List(adjacent: [d]))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b, c]))

        let graph = builder.build()
        let closure = graph.analyze.transitiveClosure()

        // Transitive closure edges:
        // A -> B, C, D (3 edges)
        // B -> D (1 edge)
        // C -> D (1 edge)
        // D -> (0 edges)
        // Total: 5 edges

        var totalEdges = 0
        for node in closure.nodes {
            totalEdges += closure[node].adjacent.count
        }

        #expect(totalEdges == 5)

        // Verify A can reach all other nodes
        #expect(closure[a].adjacent.contains(b))
        #expect(closure[a].adjacent.contains(c))
        #expect(closure[a].adjacent.contains(d))

        // Verify B and C can reach D
        #expect(closure[b].adjacent.contains(d))
        #expect(closure[c].adjacent.contains(d))

        // Verify D has no outgoing edges
        #expect(closure[d].adjacent.isEmpty)
    }

    @Test
    func `Transitive closure on linear graph`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // A -> B -> C -> D
        let d = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let c = builder.allocate(Graph.Adjacency.List(adjacent: [d]))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [c]))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()
        let closure = graph.analyze.transitiveClosure()

        // A -> B, C, D (3 edges)
        // B -> C, D (2 edges)
        // C -> D (1 edge)
        // D -> (0 edges)
        // Total: 6 edges

        var totalEdges = 0
        for node in closure.nodes {
            totalEdges += closure[node].adjacent.count
        }

        #expect(totalEdges == 6)

        // Verify A can reach all nodes
        #expect(closure[a].adjacent.count == 3)

        // Verify B can reach C and D
        #expect(closure[b].adjacent.count == 2)

        // Verify C can reach D
        #expect(closure[c].adjacent.count == 1)
    }

    @Test
    func `Transitive closure on cycle includes self-loops`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // A -> B -> C -> A (cycle)
        let a = builder.allocateHole()
        let c = builder.allocate(Graph.Adjacency.List(adjacent: [a]))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [c]))
        builder[a] = Graph.Adjacency.List(adjacent: [b])

        let graph = builder.build()
        let closure = graph.analyze.transitiveClosure()

        // In a cycle, every node can reach every other node (including itself)
        // A -> A, B, C (3 edges)
        // B -> A, B, C (3 edges)
        // C -> A, B, C (3 edges)
        // Total: 9 edges

        var totalEdges = 0
        for node in closure.nodes {
            totalEdges += closure[node].adjacent.count
        }

        #expect(totalEdges == 9)

        // Each node should be able to reach all nodes (including itself)
        #expect(closure[a].adjacent.count == 3)
        #expect(closure[b].adjacent.count == 3)
        #expect(closure[c].adjacent.count == 3)
    }

    @Test
    func `Transitive closure on empty graph`() {
        let graph = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder().build()
        let closure = graph.analyze.transitiveClosure()

        #expect(closure.isEmpty)
    }

    @Test
    func `Transitive closure preserves node count`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        let c = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [c]))
        _ = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()
        let closure = graph.analyze.transitiveClosure()

        #expect(closure.count == graph.count)
    }

    @Test
    func `Transitive closure on disconnected graph`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // A -> B,  C (disconnected)
        let c = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()
        let closure = graph.analyze.transitiveClosure()

        // A -> B (1 edge)
        // B -> (0 edges)
        // C -> (0 edges)

        #expect(closure[a].adjacent.count == 1)
        #expect(closure[a].adjacent.contains(b))
        #expect(closure[b].adjacent.isEmpty)
        #expect(closure[c].adjacent.isEmpty)
    }
}
