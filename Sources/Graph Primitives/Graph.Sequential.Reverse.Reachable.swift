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
        let count = graph.storage.count
        var result = Set_Primitives.Set<Graph.Node<Tag>>.Ordered()

        guard count > 0 else { return result }

        // Validate target
        guard target.rawValue >= 0 && target.rawValue < count else { return result }

        // Build reversed graph and run forward reachability from target
        let reversedGraph = self.reversed()

        // DFS from target on reversed graph
        var visited = try! Bit.Array(count: count)
        var stack = Stack<Graph.Node<Tag>>()

        stack.push(target)

        while let node = stack.pop() {
            guard !visited[node.rawValue] else { continue }
            visited[node.rawValue] = true
            result.insert(node)

            let payload = reversedGraph.storage[node.rawValue]
            for adjacent in payload.adjacent {
                if !visited[adjacent.rawValue] {
                    stack.push(adjacent)
                }
            }
        }

        return result
    }
}
