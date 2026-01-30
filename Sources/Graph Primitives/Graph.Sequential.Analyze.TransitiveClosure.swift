public import Identity_Primitives
public import Stack_Primitives
public import Bit_Primitives
public import Array_Primitives

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
            var builder = Graph.Sequential<Tag, Graph.Adjacency.List<Tag>>.Builder()
            return builder.build()
        }

        // For each node, compute all reachable nodes
        // Use Array.Indexed for typed subscript access
        var closureAdjacent = Array<[Graph.Node<Tag>]>.Indexed<Tag>(
            [[Graph.Node<Tag>]](repeating: [], count: Int(bitPattern: count))
        )

        for source in graph.nodes {
            var visited = Array<Bit>.Vector(count: count.retag(Bit.self))
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
                closureAdjacent[source].append(node)

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
            _ = builder.allocate(Graph.Adjacency.List(adjacent: closureAdjacent[source]))
        }

        return builder.build()
    }
}
