import Testing
import Identity_Primitives
@testable import Graph_Primitives

private enum TestTag {}

// MARK: - Reversed Graph Tests

@Suite("Graph.Sequential.Reverse.Graph")
struct ReversedGraphTests {
    @Test("Reversed graph has same edge count")
    func reversedGraphSameEdgeCount() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // Diamond: A -> B, A -> C, B -> D, C -> D (4 edges)
        let d = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [d]))
        let c = builder.allocate(Graph.Adjacency.List(adjacent: [d]))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b, c]))

        let graph = builder.build()

        // Count edges in original
        var originalEdgeCount = 0
        for i in 0..<graph.storage.count {
            originalEdgeCount += graph.storage[i].adjacent.count
        }

        // Get reversed graph
        let reversed = graph.reverse.reversed()

        // Count edges in reversed
        var reversedEdgeCount = 0
        for i in 0..<reversed.storage.count {
            reversedEdgeCount += reversed.storage[i].adjacent.count
        }

        #expect(originalEdgeCount == 4)
        #expect(reversedEdgeCount == 4)
    }

    @Test("Reversed graph reverses edges correctly")
    func reversedGraphReversesEdges() {
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
        #expect(reversed.storage[a.rawValue].adjacent.isEmpty)
        #expect(reversed.storage[b.rawValue].adjacent == [a])
        #expect(reversed.storage[c.rawValue].adjacent == [b])
    }

    @Test("Reversed graph preserves node count")
    func reversedGraphPreservesNodeCount() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        let c = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [c]))
        _ = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()
        let reversed = graph.reverse.reversed()

        #expect(graph.storage.count == reversed.storage.count)
    }

    @Test("Empty graph reverses to empty graph")
    func emptyGraphReversesToEmpty() {
        let graph = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder().build()
        let reversed = graph.reverse.reversed()

        #expect(reversed.storage.isEmpty)
    }

    @Test("Single node graph reverses correctly")
    func singleNodeReversesCorrectly() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()
        _ = builder.allocate(Graph.Adjacency.List(adjacent: []))

        let graph = builder.build()
        let reversed = graph.reverse.reversed()

        #expect(reversed.storage.count == 1)
        #expect(reversed.storage[0].adjacent.isEmpty)
    }

    @Test("Self-loop reverses to self-loop")
    func selfLoopReversesToSelfLoop() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()
        let a = builder.allocateHole()
        builder[a] = Graph.Adjacency.List(adjacent: [a])

        let graph = builder.build()
        let reversed = graph.reverse.reversed()

        #expect(reversed.storage[a.rawValue].adjacent == [a])
    }
}

// MARK: - Backward Reachability Tests

@Suite("Graph.Sequential.Reverse.Reachable")
struct BackwardReachabilityTests {
    @Test("Backward reachable equals forward reachable on reversed graph")
    func backwardReachableEqualsForwardOnReversed() {
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

    @Test("Backward reachable from disconnected node")
    func backwardReachableDisconnected() {
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

    @Test("Backward reachable includes target")
    func backwardReachableIncludesTarget() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        let a = builder.allocate(Graph.Adjacency.List(adjacent: []))

        let graph = builder.build()

        let backwardReachable = graph.reverse.reachable(to: a)

        #expect(backwardReachable.contains(a))
        #expect(backwardReachable.count == 1)
    }

    @Test("Backward reachable on empty graph returns empty")
    func backwardReachableEmptyGraph() {
        let graph = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder().build()
        let invalid = Graph.Node<TestTag>(rawValue: 0)

        let backwardReachable = graph.reverse.reachable(to: invalid)

        #expect(backwardReachable.isEmpty)
    }

    @Test("Backward reachable with invalid node returns empty")
    func backwardReachableInvalidNode() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()
        _ = builder.allocate(Graph.Adjacency.List(adjacent: []))

        let graph = builder.build()
        let invalid = Graph.Node<TestTag>(rawValue: 999)

        let backwardReachable = graph.reverse.reachable(to: invalid)

        #expect(backwardReachable.isEmpty)
    }

    @Test("Backward reachable in diamond graph")
    func backwardReachableDiamond() {
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

    @Test("Backward reachable with cycle")
    func backwardReachableWithCycle() {
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
