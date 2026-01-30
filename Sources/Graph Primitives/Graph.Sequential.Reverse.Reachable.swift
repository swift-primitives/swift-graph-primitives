public import Identity_Primitives
public import Stack_Primitives
public import Bit_Primitives
public import Set_Primitives
public import Array_Primitives

extension Graph.Sequential.Reverse {
    /// Nodes that can reach the target (backward reachability).
    ///
    /// Uses `Stack` for DFS traversal and `Bit.Array` for visited tracking.
    ///
    /// - Parameter target: The target node.
    /// - Returns: Ordered set of nodes that can reach the target, including the target itself.
    /// - Complexity: O(V + E)
    @inlinable
    public func reachable(to target: Graph.Node<Tag>) -> Set_Primitives.Set<Graph.Node<Tag>>.Ordered {
        let count = graph.count
        var result = Set_Primitives.Set<Graph.Node<Tag>>.Ordered()

        guard count > .zero else { return result }

        // Validate target
        guard target < count else { return result }

        // Build reversed graph and run forward reachability from target
        let reversedGraph = self.reversed()

        // DFS from target on reversed graph
        var visited = Array<Bit>.Vector(count: count.retag(Bit.self))
        var stack = Stack<Graph.Node<Tag>>()

        stack.push(target)

        while let node = stack.pop() {
            let idx = node.retag(Bit.self)
            guard !visited[idx] else { continue }
            visited[idx] = true
            result.insert(node)

            let payload = reversedGraph.storage[node]
            for adjacent in payload.adjacent {
                let adjIdx = adjacent.retag(Bit.self)
                if !visited[adjIdx] {
                    stack.push(adjacent)
                }
            }
        }

        return result
    }
}
