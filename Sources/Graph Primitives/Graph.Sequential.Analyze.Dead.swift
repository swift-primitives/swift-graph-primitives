public import Identity_Primitives
public import Stack_Primitives
public import Bit_Primitives
public import Set_Primitives
public import Array_Primitives

extension Graph.Sequential.Analyze {
    /// Nodes unreachable from roots.
    ///
    /// Uses `Stack` for DFS and `Bit.Array` for visited tracking.
    ///
    /// - Parameter roots: Starting nodes for reachability analysis.
    /// - Returns: Ordered set of nodes not reachable from any root.
    /// - Complexity: O(V + E)
    @inlinable
    public func dead(from roots: some Swift.Sequence<Graph.Node<Tag>>) -> Set_Primitives.Set<Graph.Node<Tag>>.Ordered {
        let count = graph.storage.count
        var result = Set_Primitives.Set<Graph.Node<Tag>>.Ordered()

        guard count > 0 else { return result }

        // Mark all reachable nodes using DFS
        var visited = try! Array<Bit>.Packed(count: count)
        var stack = Stack<Graph.Node<Tag>>()

        // Add all valid roots to the stack
        for root in roots {
            let idx = Bit.Index(root.position)
            if root.position >= 0 && root.position < count && !visited[idx] {
                stack.push(root)
            }
        }

        // DFS to mark reachable nodes
        while let node = stack.pop() {
            let idx = Bit.Index(node.position)
            guard !visited[idx] else { continue }
            visited[idx] = true

            let payload = graph.storage[node.position]
            for adjacent in extract.adjacent(payload) {
                let adjIdx = Bit.Index(adjacent.position)
                if !visited[adjIdx] {
                    stack.push(adjacent)
                }
            }
        }

        // Collect unvisited nodes as dead
        for i in 0..<count {
            let idx = Bit.Index(__unchecked: (), position: i)
            if !visited[idx] {
                result.insert(Graph.Node<Tag>(__unchecked: (), position: i))
            }
        }

        return result
    }
}
