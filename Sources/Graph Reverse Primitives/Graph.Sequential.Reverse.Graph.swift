public import Buffer_Linear_Bounded_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives
public import Column_Primitives
// Hoisted carrier spelled directly ([DS-025]/[DS-028]); not surfaced through the umbrella @_exported import.
public import Fixed_Primitive
public import Fixed_Primitives
public import Ownership_Shared_Primitive
public import Tagged_Collection_Primitives
public import Tagged_Primitives
public import Vector_Primitives

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
            let builder = Graph.Sequential<Tag, Graph.Adjacency.List<Tag>>.Builder()
            return builder.build()
        }

        // Build reversed adjacency lists using a plain Fixed scratch; retag node
        // indices into the Element domain at each access.
        var reversedAdjacent = __Fixed<Column.Bounded<[Graph.Node<Tag>]>>(repeating: [], count: count.retag([Graph.Node<Tag>].self))

        for source in graph.nodes {
            let payload = graph.storage[source]

            for target in extract.adjacent(payload) {
                // Original edge: source → target
                // Reversed edge: target → source
                reversedAdjacent[target.retag([Graph.Node<Tag>].self)].append(source)
            }
        }

        // Build the reversed graph
        var builder = Graph.Sequential<Tag, Graph.Adjacency.List<Tag>>.Builder(capacity: count)
        for source in graph.nodes {
            _ = builder.allocate(Graph.Adjacency.List(adjacent: reversedAdjacent[source.retag([Graph.Node<Tag>].self)]))
        }

        return builder.build()
    }
}
