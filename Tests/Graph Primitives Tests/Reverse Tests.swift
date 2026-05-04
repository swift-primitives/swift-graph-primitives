import Testing
import Graph_Primitives_Test_Support

private enum TestTag {}

// MARK: - Reversed Graph Tests

@Suite("Graph.Sequential.Reverse.Graph")
struct ReversedGraphTests {
    @Test
    func `Reversed graph has same edge count`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // Diamond: A -> B, A -> C, B -> D, C -> D (4 edges)
        let d = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [d]))
        let c = builder.allocate(Graph.Adjacency.List(adjacent: [d]))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b, c]))

        let graph = builder.build()

        // Count edges in original
        var originalEdgeCount = 0
        for node in graph.nodes {
            originalEdgeCount += graph[node].adjacent.count
        }

        // Get reversed graph
        let reversed = graph.reverse.reversed()

        // Count edges in reversed
        var reversedEdgeCount = 0
        for node in reversed.nodes {
            reversedEdgeCount += reversed[node].adjacent.count
        }

        #expect(originalEdgeCount == 4)
        #expect(reversedEdgeCount == 4)
    }

    @Test
    func `Reversed graph reverses edges correctly`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // A -> B -> C
        let c = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [c]))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()
        let reversed = graph.reverse.reversed()

        // Original: A -> B -> C
        // Reversed: C -> B -> A

        // In reversed graph:
        // - A has no outgoing edges
        // - B has edge to A
        // - C has edge to B
        #expect(reversed[a].adjacent.isEmpty)
        #expect(reversed[b].adjacent == [a])
        #expect(reversed[c].adjacent == [b])
    }

    @Test
    func `Reversed graph preserves node count`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        let c = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [c]))
        _ = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()
        let reversed = graph.reverse.reversed()

        #expect(graph.count == reversed.count)
    }

    @Test
    func `Empty graph reverses to empty graph`() {
        let graph = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder().build()
        let reversed = graph.reverse.reversed()

        #expect(reversed.isEmpty)
    }

    @Test
    func `Single node graph reverses correctly`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()
        _ = builder.allocate(Graph.Adjacency.List(adjacent: []))

        let graph = builder.build()
        let reversed = graph.reverse.reversed()

        let node0: Graph.Node<TestTag> = 0
        #expect(reversed.count == 1)
        #expect(reversed[node0].adjacent.isEmpty)
    }

    @Test
    func `Self-loop reverses to self-loop`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()
        let a = builder.allocateHole()
        builder[a] = Graph.Adjacency.List(adjacent: [a])

        let graph = builder.build()
        let reversed = graph.reverse.reversed()

        #expect(reversed[a].adjacent == [a])
    }
}

// MARK: - Backward Reachability Tests

@Suite("Graph.Sequential.Reverse.Reachable")
struct BackwardReachabilityTests {
    @Test
    func `Backward reachable equals forward reachable on reversed graph`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // A -> B -> C
        let c = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [c]))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()

        // Backward reachable to C should be {A, B, C}
        let backwardReachable = graph.reverse.reachable(to: c)

        #expect(backwardReachable.contains(a))
        #expect(backwardReachable.contains(b))
        #expect(backwardReachable.contains(c))
        #expect(backwardReachable.count == 3)
    }

    @Test
    func `Backward reachable from disconnected node`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // A -> B,  C (disconnected)
        let c = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()

        // Backward reachable to C should only be {C}
        let backwardReachable = graph.reverse.reachable(to: c)

        #expect(backwardReachable.contains(c))
        #expect(!backwardReachable.contains(a))
        #expect(!backwardReachable.contains(b))
        #expect(backwardReachable.count == 1)
    }

    @Test
    func `Backward reachable includes target`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        let a = builder.allocate(Graph.Adjacency.List(adjacent: []))

        let graph = builder.build()

        let backwardReachable = graph.reverse.reachable(to: a)

        #expect(backwardReachable.contains(a))
        #expect(backwardReachable.count == 1)
    }

    @Test
    func `Backward reachable on empty graph returns empty`() {
        let graph = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder().build()
        let invalid: Graph.Node<TestTag> = 0

        let backwardReachable = graph.reverse.reachable(to: invalid)

        #expect(backwardReachable.isEmpty)
    }

    @Test
    func `Backward reachable with invalid node returns empty`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()
        _ = builder.allocate(Graph.Adjacency.List(adjacent: []))

        let graph = builder.build()
        let invalid = Graph.Node<TestTag>(_unchecked: Ordinal(999))

        let backwardReachable = graph.reverse.reachable(to: invalid)

        #expect(backwardReachable.isEmpty)
    }

    @Test
    func `Backward reachable in diamond graph`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // Diamond: A -> B, A -> C, B -> D, C -> D
        let d = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [d]))
        let c = builder.allocate(Graph.Adjacency.List(adjacent: [d]))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b, c]))

        let graph = builder.build()

        // Backward reachable to D should be {A, B, C, D}
        let backwardReachable = graph.reverse.reachable(to: d)

        #expect(backwardReachable.contains(a))
        #expect(backwardReachable.contains(b))
        #expect(backwardReachable.contains(c))
        #expect(backwardReachable.contains(d))
        #expect(backwardReachable.count == 4)
    }

    @Test
    func `Backward reachable with cycle`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // A -> B -> C -> A (cycle)
        let a = builder.allocateHole()
        let c = builder.allocate(Graph.Adjacency.List(adjacent: [a]))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [c]))
        builder[a] = Graph.Adjacency.List(adjacent: [b])

        let graph = builder.build()

        // Backward reachable to any node should include all nodes (due to cycle)
        let backwardReachable = graph.reverse.reachable(to: a)

        #expect(backwardReachable.contains(a))
        #expect(backwardReachable.contains(b))
        #expect(backwardReachable.contains(c))
        #expect(backwardReachable.count == 3)
    }
}
