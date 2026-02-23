import Testing
import Graph_Primitives_Test_Support

private enum TestTag {}

// MARK: - Dead Nodes Tests

@Suite("Graph.Sequential.Analyze.Dead")
struct DeadNodesTests {
    @Test("Dead nodes in disconnected graph")
    func deadNodesInDisconnectedGraph() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // A -> B,  C, D (C and D disconnected)
        let d = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let c = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()

        let dead = graph.analyze.dead(from: [a])

        #expect(dead.contains(c))
        #expect(dead.contains(d))
        #expect(!dead.contains(a))
        #expect(!dead.contains(b))
        #expect(dead.count == 2)
    }

    @Test("Dead nodes from all roots is empty")
    func deadNodesFromAllRootsIsEmpty() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // A -> B -> C
        let c = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [c]))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()

        let dead = graph.analyze.dead(from: [a])

        #expect(dead.isEmpty)
    }

    @Test("Dead nodes from empty roots")
    func deadNodesFromEmptyRoots() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        let c = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [c]))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()

        let dead = graph.analyze.dead(from: [] as [Graph.Node<TestTag>])

        #expect(dead.count == 3)
        #expect(dead.contains(a))
        #expect(dead.contains(b))
        #expect(dead.contains(c))
    }

    @Test("Dead nodes in empty graph")
    func deadNodesInEmptyGraph() {
        let graph = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder().build()

        let dead = graph.analyze.dead(from: [] as [Graph.Node<TestTag>])

        #expect(dead.isEmpty)
    }

    @Test("Dead nodes from multiple roots")
    func deadNodesFromMultipleRoots() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // A -> B,  C -> D,  E (disconnected)
        let e = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let d = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let c = builder.allocate(Graph.Adjacency.List(adjacent: [d]))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()

        let dead = graph.analyze.dead(from: [a, c])

        #expect(dead.contains(e))
        #expect(!dead.contains(a))
        #expect(!dead.contains(b))
        #expect(!dead.contains(c))
        #expect(!dead.contains(d))
        #expect(dead.count == 1)
    }
}

// MARK: - Transitive Closure Tests

@Suite("Graph.Sequential.Analyze.TransitiveClosure")
struct TransitiveClosureTests {
    @Test("Transitive closure on diamond DAG has correct edge count")
    func transitiveClosureDiamondDAG() {
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

    @Test("Transitive closure on linear graph")
    func transitiveClosureLinearGraph() {
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

    @Test("Transitive closure on cycle includes self-loops")
    func transitiveClosureOnCycle() {
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

    @Test("Transitive closure on empty graph")
    func transitiveClosureEmptyGraph() {
        let graph = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder().build()
        let closure = graph.analyze.transitiveClosure()

        #expect(closure.isEmpty)
    }

    @Test("Transitive closure preserves node count")
    func transitiveClosurePreservesNodeCount() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        let c = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [c]))
        _ = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()
        let closure = graph.analyze.transitiveClosure()

        #expect(closure.count == graph.count)
    }

    @Test("Transitive closure on disconnected graph")
    func transitiveClosureDisconnectedGraph() {
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
