public import Identity_Primitives
public import Stack_Primitives
public import Bit_Primitives
public import Array_Primitives
public import Set_Primitives

extension Graph.Sequential.Analyze {
    /// Returns the set of nodes reachable from the given roots.
    ///
    /// Uses `Stack` for DFS and `Array<Bit>.Packed` for visited tracking.
    ///
    /// - Parameter roots: The nodes to start reachability analysis from.
    /// - Returns: Ordered set of all nodes reachable from any root (includes roots themselves).
    /// - Complexity: O(V + E)
    @inlinable
    public func reachable(from roots: some Swift.Sequence<Graph.Node<Tag>>) -> Set_Primitives.Set<Graph.Node<Tag>>.Ordered {
        let count = graph.storage.count
        var result = Set_Primitives.Set<Graph.Node<Tag>>.Ordered()
        guard count > 0 else { return result }

        var visited = try! Array<Bit>.Packed(count: count)
        var stack = Stack<Graph.Node<Tag>>()

        for root in roots {
            let rootIndex = root.position
            let idx = Bit.Index(root.position)
            if rootIndex >= 0 && rootIndex < count && !visited[idx] {
                stack.push(root)
            }
        }

        result.reserveCapacity(count)

        while let node = stack.pop() {
            let idx = Bit.Index(node.position)
            guard !visited[idx] else { continue }
            visited[idx] = true
            result.insert(node)

            let payload = graph.storage[node.position]
            for adjacent in extract.adjacent(payload) {
                let adjIdx = Bit.Index(adjacent.position)
                if !visited[adjIdx] {
                    stack.push(adjacent)
                }
            }
        }

        return result
    }

    /// Returns the set of nodes reachable from a single root.
    ///
    /// Uses `Stack` for DFS and `Array<Bit>.Packed` for visited tracking.
    ///
    /// - Parameter root: The node to start reachability analysis from.
    /// - Returns: Ordered set of all nodes reachable from the root.
    /// - Complexity: O(V + E)
    @inlinable
    public func reachable(from root: Graph.Node<Tag>) -> Set_Primitives.Set<Graph.Node<Tag>>.Ordered {
        reachable(from: Swift.CollectionOfOne(root))
    }
}
