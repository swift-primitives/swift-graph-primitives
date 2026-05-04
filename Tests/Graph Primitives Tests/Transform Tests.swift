import Testing
import Graph_Primitives_Test_Support

private enum TestTag {}

private func orderedSet(_ nodes: Graph.Node<TestTag>...) -> Set_Primitives.Set<Graph.Node<TestTag>>.Ordered {
    var set = Set_Primitives.Set<Graph.Node<TestTag>>.Ordered()
    for node in nodes {
        _ = set.insert(node)
    }
    return set
}

// MARK: - Payload Mapping Tests

@Suite("Graph.Sequential.Transform.Payloads")
struct PayloadMappingTests {
    @Test
    func `Payload mapping preserves node count`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        let c = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [c]))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b, c]))

        let graph = builder.build()

        // Map adjacency to count of adjacent nodes
        let mapped = graph.transform.payloads { $0.adjacent.count }

        #expect(mapped.count == graph.count)
        #expect(mapped.count == 3)
        #expect(mapped[a] == 2) // A has 2 edges
        #expect(mapped[b] == 1) // B has 1 edge
        #expect(mapped[c] == 0) // C has 0 edges
    }

    @Test
    func `Payload mapping on empty graph`() {
        let builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()
        let graph = builder.build()

        let mapped = graph.transform.payloads { $0.adjacent.count }

        #expect(mapped.count == 0)
        #expect(mapped.isEmpty)
    }

    @Test
    func `Payload mapping changes payload type`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        let a = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [a]))

        let graph = builder.build()

        // Map to string representation
        let mapped: Graph.Sequential<TestTag, String> = graph.transform.payloads { payload in
            "edges: \(payload.adjacent.count)"
        }

        #expect(mapped[a] == "edges: 0")
        #expect(mapped[b] == "edges: 1")
    }
}

// MARK: - Induced Subgraph Tests

@Suite("Graph.Sequential.Transform.Subgraph")
struct SubgraphTests {
    @Test
    func `Induced subgraph drops edges to excluded nodes`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // Diamond: A -> B, A -> C, B -> D, C -> D
        let d = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [d]))
        let c = builder.allocate(Graph.Adjacency.List(adjacent: [d]))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b, c]))

        let graph = builder.build()

        // Subgraph with only A, B - should drop edges to C and D
        let subgraph = graph.transform.subgraph(inducedBy: orderedSet(a, b))

        #expect(subgraph != nil)
        #expect(subgraph!.count == 2)

        // Verify remapped indices are valid
        for node in subgraph!.nodes {
            let payload = subgraph![node]
            for adjacent in payload.adjacent {
                #expect(adjacent < subgraph!.count)
            }
        }
    }

    @Test
    func `Induced subgraph remaps to sequential IDs`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        let d = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let c = builder.allocate(Graph.Adjacency.List(adjacent: [d]))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [c, d]))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()

        // Subgraph with B, C, D (excluding A)
        let subgraph = graph.transform.subgraph(inducedBy: orderedSet(b, c, d))

        #expect(subgraph != nil)
        #expect(subgraph!.count == 3)

        // All adjacency references should be within 0..<3
        for node in subgraph!.nodes {
            let payload = subgraph![node]
            for adjacent in payload.adjacent {
                #expect(adjacent < 3)
            }
        }
    }

    @Test
    func `Induced subgraph returns nil for invalid nodes`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        let a = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [a]))

        let graph = builder.build()

        // Create an invalid node
        let invalidNode = Graph.Node<TestTag>(_unchecked: Ordinal(999))

        // Subgraph with invalid node should return nil
        let subgraph = graph.transform.subgraph(inducedBy: orderedSet(a, invalidNode))

        #expect(subgraph == nil)
    }

    @Test
    func `Induced subgraph on all nodes returns equivalent graph`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        let b = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()

        // Subgraph with all nodes
        let subgraph = graph.transform.subgraph(inducedBy: orderedSet(a, b))

        #expect(subgraph != nil)
        #expect(subgraph!.count == graph.count)

        // Edge count should be preserved
        var originalEdges = 0
        var subgraphEdges = 0

        for node in graph.nodes {
            originalEdges += graph[node].adjacent.count
        }
        for node in subgraph!.nodes {
            subgraphEdges += subgraph![node].adjacent.count
        }

        #expect(subgraphEdges == originalEdges)
    }

    @Test
    func `Induced subgraph on empty set returns empty graph`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        _ = builder.allocate(Graph.Adjacency.List(adjacent: []))

        let graph = builder.build()

        let subgraph = graph.transform.subgraph(inducedBy: orderedSet())

        #expect(subgraph != nil)
        #expect(subgraph!.count == 0)
        #expect(subgraph!.isEmpty)
    }

    @Test
    func `Induced subgraph preserves edges within subgraph`() {
        var builder = Graph.Sequential<TestTag, Graph.Adjacency.List<TestTag>>.Builder()

        // A -> B -> C (linear chain)
        let c = builder.allocate(Graph.Adjacency.List(adjacent: []))
        let b = builder.allocate(Graph.Adjacency.List(adjacent: [c]))
        let a = builder.allocate(Graph.Adjacency.List(adjacent: [b]))

        let graph = builder.build()

        // Subgraph with A and B only
        let subgraph = graph.transform.subgraph(inducedBy: orderedSet(a, b))

        #expect(subgraph != nil)
        #expect(subgraph!.count == 2)

        // A (remapped to 0 or 1) should have edge to B (remapped to the other)
        // B should have no edges (its only edge was to C which is excluded)

        var totalEdges = 0
        for node in subgraph!.nodes {
            totalEdges += subgraph![node].adjacent.count
        }

        // Only edge A->B should remain (B->C is dropped)
        #expect(totalEdges == 1)
    }
}
