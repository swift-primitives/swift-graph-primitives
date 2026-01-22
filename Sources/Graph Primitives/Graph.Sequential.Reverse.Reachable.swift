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
        guard target.position.rawValue >= 0 && target.position.rawValue < count else { return result }

        // Build reversed graph and run forward reachability from target
        let reversedGraph = self.reversed()

        // DFS from target on reversed graph
        var visited = try! Array<Bit>.Packed(count: count)
        var stack = Stack<Graph.Node<Tag>>()

        stack.push(target)

        while let node = stack.pop() {
            let idx = Bit.Index(node.position)
            guard !visited[idx] else { continue }
            visited[idx] = true
            result.insert(node)

            let payload = reversedGraph.storage[node.position.rawValue]
            for adjacent in payload.adjacent {
                let adjIdx = Bit.Index(adjacent.position)
                if !visited[adjIdx] {
                    stack.push(adjacent)
                }
            }
        }

        return result
    }
}
