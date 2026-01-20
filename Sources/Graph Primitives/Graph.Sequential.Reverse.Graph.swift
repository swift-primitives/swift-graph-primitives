public import Identity_Primitives

extension Graph.Sequential.Reverse {
    /// Creates a graph with all edges reversed.
    ///
    /// For each edge A→B in the original graph, the reversed graph has B→A.
    ///
    /// - Returns: A new graph where all adjacencies are reversed.
    /// - Complexity: O(V + E)
    @inlinable
    public func reversed() -> Graph.Sequential<Tag, Graph.Adjacency.List<Tag>> {
        let count = graph.storage.count
        guard count > 0 else {
            var builder = Graph.Sequential<Tag, Graph.Adjacency.List<Tag>>.Builder()
            return builder.build()
        }

        // Build reversed adjacency lists
        var reversedAdjacent = [[Graph.Node<Tag>]](repeating: [], count: count)

        for sourceIndex in 0..<count {
            let payload = graph.storage[sourceIndex]
            let source = Graph.Node<Tag>(rawValue: sourceIndex)

            for target in extract.adjacent(payload) {
                // Original edge: source → target
                // Reversed edge: target → source
                reversedAdjacent[target.rawValue].append(source)
            }
        }

        // Build the reversed graph
        var builder = Graph.Sequential<Tag, Graph.Adjacency.List<Tag>>.Builder(capacity: count)
        for adjacent in reversedAdjacent {
            _ = builder.allocate(Graph.Adjacency.List(adjacent: adjacent))
        }

        return builder.build()
    }
}
