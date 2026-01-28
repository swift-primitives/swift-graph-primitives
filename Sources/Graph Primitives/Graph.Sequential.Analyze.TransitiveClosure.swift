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
        let count = graph.storage.count
        guard count > 0 else {
            var builder = Graph.Sequential<Tag, Graph.Adjacency.List<Tag>>.Builder()
            return builder.build()
        }

        // For each node, compute all reachable nodes
        var closureAdjacent = [[Graph.Node<Tag>]](repeating: [], count: count)

        for sourceIndex in 0..<count {
            var visited = try! Array<Bit>.Packed(count: count)
            var stack = Stack<Graph.Node<Tag>>()

            // Start DFS from source's adjacent nodes (not source itself initially)
            let sourcePayload = graph.storage[sourceIndex]
            for adjacent in extract.adjacent(sourcePayload) {
                stack.push(adjacent)
            }

            // DFS to find all reachable nodes
            while let node = stack.pop() {
                let idx = Bit.Index(node.position)
                guard !visited[idx] else { continue }
                visited[idx] = true

                // Add to closure (node is reachable from source)
                closureAdjacent[sourceIndex].append(node)

                let payload = graph.storage[node.position]
                for adjacent in extract.adjacent(payload) {
                    let adjIdx = Bit.Index(adjacent.position)
                    if !visited[adjIdx] {
                        stack.push(adjacent)
                    }
                }
            }
        }

        // Build the closure graph
        var builder = Graph.Sequential<Tag, Graph.Adjacency.List<Tag>>.Builder(capacity: count)
        for adjacent in closureAdjacent {
            _ = builder.allocate(Graph.Adjacency.List(adjacent: adjacent))
        }

        return builder.build()
    }
}
