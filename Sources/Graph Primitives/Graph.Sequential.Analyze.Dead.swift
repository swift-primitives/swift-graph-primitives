public import Identity_Primitives
public import Stack_Primitives
public import Bit_Primitives
public import Set_Primitives

extension Graph.Sequential.Analyze {
    /// Nodes unreachable from roots.
    ///
    /// Uses `Stack` for DFS and `Bit.Array` for visited tracking.
    ///
    /// - Parameter roots: Starting nodes for reachability analysis.
    /// - Returns: Ordered set of nodes not reachable from any root.
    /// - Complexity: O(V + E)
    @inlinable
    public func dead(from roots: some Sequence<Graph.Node<Tag>>) -> Set_Primitives.Set<Graph.Node<Tag>>.Ordered {
        let count = graph.storage.count
        var result = Set_Primitives.Set<Graph.Node<Tag>>.Ordered()

        guard count > 0 else { return result }

        // Mark all reachable nodes using DFS
        var visited = try! Bit.Array(count: count)
        var stack = Stack<Graph.Node<Tag>>()

        // Add all valid roots to the stack
        for root in roots {
            if root.rawValue >= 0 && root.rawValue < count && !visited[root.rawValue] {
                stack.push(root)
            }
        }

        // DFS to mark reachable nodes
        while let node = stack.pop() {
            guard !visited[node.rawValue] else { continue }
            visited[node.rawValue] = true

            let payload = graph.storage[node.rawValue]
            for adjacent in extract.adjacent(payload) {
                if !visited[adjacent.rawValue] {
                    stack.push(adjacent)
                }
            }
        }

        // Collect unvisited nodes as dead
        for i in 0..<count {
            if !visited[i] {
                result.insert(Graph.Node<Tag>(rawValue: i))
            }
        }

        return result
    }
}
