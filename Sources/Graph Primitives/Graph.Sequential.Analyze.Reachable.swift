public import Identity_Primitives
public import Stack_Primitives
public import Bit_Primitives

extension Graph.Sequential.Analyze {
    /// Returns the set of nodes reachable from the given roots.
    ///
    /// Uses `Stack` for DFS and `Bit.Array` for visited tracking.
    ///
    /// - Parameter roots: The nodes to start reachability analysis from.
    /// - Returns: All nodes reachable from any root (includes roots themselves).
    /// - Complexity: O(V + E)
    @inlinable
    public func reachable(from roots: some Sequence<Graph.Node<Tag>>) -> Swift.Set<Graph.Node<Tag>> {
        let count = graph.storage.count
        guard count > 0 else { return [] }

        var visited = try! Bit.Array(count: count)
        var stack = Stack<Graph.Node<Tag>>()

        for root in roots {
            let rootIndex = root.rawValue
            if rootIndex >= 0 && rootIndex < count && !visited[rootIndex] {
                stack.push(root)
            }
        }

        var result = Swift.Set<Graph.Node<Tag>>()
        result.reserveCapacity(count)

        while let node = stack.pop() {
            let nodeIndex = node.rawValue
            guard !visited[nodeIndex] else { continue }
            visited[nodeIndex] = true
            result.insert(node)

            let payload = graph.storage[nodeIndex]
            for adjacent in extract.adjacent(payload) {
                if !visited[adjacent.rawValue] {
                    stack.push(adjacent)
                }
            }
        }

        return result
    }

    /// Returns the set of nodes reachable from a single root.
    ///
    /// Uses `Stack` for DFS and `Bit.Array` for visited tracking.
    ///
    /// - Parameter root: The node to start reachability analysis from.
    /// - Returns: All nodes reachable from the root.
    /// - Complexity: O(V + E)
    @inlinable
    public func reachable(from root: Graph.Node<Tag>) -> Swift.Set<Graph.Node<Tag>> {
        reachable(from: CollectionOfOne(root))
    }
}
