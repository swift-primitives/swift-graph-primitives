public import Identity_Primitives
public import Array_Primitives

extension Graph.Sequential.Reverse {
    /// Creates a graph with all edges reversed.
    ///
    /// For each edge A→B in the original graph, the reversed graph has B→A.
    ///
    /// - Returns: A new graph where all adjacencies are reversed.
    /// - Complexity: O(V + E)
    @inlinable
    public func reversed() -> Graph.Sequential<Tag, Graph.Adjacency.List<Tag>> {
        let count = graph.count
        guard count > .zero else {
            var builder = Graph.Sequential<Tag, Graph.Adjacency.List<Tag>>.Builder()
            return builder.build()
        }

        // Build reversed adjacency lists using typed indexed array
        var reversedAdjacent = Array<[Graph.Node<Tag>]>.Fixed.Indexed<Tag>(repeating: [], count: count)

        for source in graph.nodes {
            let payload = graph.storage[source]

            for target in extract.adjacent(payload) {
                // Original edge: source → target
                // Reversed edge: target → source
                reversedAdjacent[target].append(source)
            }
        }

        // Build the reversed graph
        var builder = Graph.Sequential<Tag, Graph.Adjacency.List<Tag>>.Builder(capacity: count)
        for source in graph.nodes {
            _ = builder.allocate(Graph.Adjacency.List(adjacent: reversedAdjacent[source]))
        }

        return builder.build()
    }
}
