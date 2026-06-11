public import Bit_Vector_Primitives
public import Buffer_Linear_Bounded_Primitive
public import Buffer_Linear_Primitive
public import Column_Primitives
public import Fixed_Primitives
public import Shared_Primitive
public import Stack_Primitives
public import Tagged_Collection_Primitives
public import Tagged_Primitives
public import Vector_Primitives

extension Graph.Sequential.Analyze {
    /// Computes transitive closure.
    ///
    /// Uses `Stack` for DFS per node and `Bit.Array` for visited tracking.
    ///
    /// - Returns: Graph where edge (u,v) exists iff v is reachable from u.
    /// - Complexity: O(V * (V + E))
    @inlinable
    public func transitiveClosure() -> Graph.Sequential<Tag, Graph.Adjacency.List<Tag>> {
        let count = graph.count
        guard count > .zero else {
            let builder = Graph.Sequential<Tag, Graph.Adjacency.List<Tag>>.Builder()
            return builder.build()
        }

        // For each node, compute all reachable nodes
        // Plain Fixed scratch; retag node indices into the Element domain.
        var closureAdjacent = Fixed<Column.Bounded<[Graph.Node<Tag>]>>(repeating: [], count: count.retag([Graph.Node<Tag>].self))

        for source in graph.nodes {
            let visited = Bit.Vector(capacity: count.retag(Bit.self))
            var stack = Stack<Graph.Node<Tag>>()

            // Start DFS from source's adjacent nodes (not source itself initially)
            let sourcePayload = graph.storage[source]
            for adjacent in extract.adjacent(sourcePayload) {
                stack.push(adjacent)
            }

            // DFS to find all reachable nodes
            while let node = stack.pop() {
                let idx = node.retag(Bit.self)
                guard !visited[idx] else { continue }
                visited[idx] = true

                // Add to closure (node is reachable from source)
                closureAdjacent[source.retag([Graph.Node<Tag>].self)].append(node)

                let payload = graph.storage[node]
                for adjacent in extract.adjacent(payload) {
                    let adjIdx = adjacent.retag(Bit.self)
                    if !visited[adjIdx] {
                        stack.push(adjacent)
                    }
                }
            }
        }

        // Build the closure graph
        var builder = Graph.Sequential<Tag, Graph.Adjacency.List<Tag>>.Builder(capacity: count)
        for source in graph.nodes {
            _ = builder.allocate(Graph.Adjacency.List(adjacent: closureAdjacent[source.retag([Graph.Node<Tag>].self)]))
        }

        return builder.build()
    }
}
