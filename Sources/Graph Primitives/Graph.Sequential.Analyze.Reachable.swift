public import Identity_Primitives
public import Stack_Primitives
public import Bit_Primitives
public import Array_Primitives

extension Graph.Sequential.Analyze {
    /// Returns the set of nodes reachable from the given roots.
    ///
    /// Uses `Stack` for DFS and `Bit.Array` for visited tracking.
    ///
    /// - Parameter roots: The nodes to start reachability analysis from.
    /// - Returns: All nodes reachable from any root (includes roots themselves).
    /// - Complexity: O(V + E)
    @inlinable
    public func reachable(from roots: some Swift.Sequence<Graph.Node<Tag>>) -> Swift.Set<Graph.Node<Tag>> {
        let count = graph.storage.count
        guard count > 0 else { return [] }

        var visited = try! Array<Bit>.Packed(count: count)
        var stack = Stack<Graph.Node<Tag>>()

        for root in roots {
            let rootIndex = root.position.rawValue
            let idx = Bit.Index(root.position)
            if rootIndex >= 0 && rootIndex < count && !visited[idx] {
                stack.push(root)
            }
        }

        var result = Swift.Set<Graph.Node<Tag>>()
        result.reserveCapacity(count)

        while let node = stack.pop() {
            let idx = Bit.Index(node.position)
            guard !visited[idx] else { continue }
            visited[idx] = true
            result.insert(node)

            let payload = graph.storage[node.position.rawValue]
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
    /// Uses `Stack` for DFS and `Bit.Array` for visited tracking.
    ///
    /// - Parameter root: The node to start reachability analysis from.
    /// - Returns: All nodes reachable from the root.
    /// - Complexity: O(V + E)
    @inlinable
    public func reachable(from root: Graph.Node<Tag>) -> Swift.Set<Graph.Node<Tag>> {
        reachable(from: Swift.CollectionOfOne(root))
    }
}
