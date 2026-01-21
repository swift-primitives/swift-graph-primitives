public import Identity_Primitives
public import Bit_Primitives
public import Array_Primitives

extension Graph.Sequential.Path {
    /// Whether a path exists from source to target.
    ///
    /// Uses BFS for traversal and `Bit.Array` for visited tracking.
    ///
    /// - Parameters:
    ///   - source: Starting node.
    ///   - target: Destination node.
    /// - Returns: `true` if a path exists, `false` otherwise.
    /// - Complexity: O(V + E)
    @inlinable
    public func exists(from source: Graph.Node<Tag>, to target: Graph.Node<Tag>) -> Bool {
        let count = graph.storage.count
        guard count > 0 else { return false }

        // Validate nodes
        guard source.rawValue >= 0 && source.rawValue < count else { return false }
        guard target.rawValue >= 0 && target.rawValue < count else { return false }

        // Same node is trivially reachable
        if source == target { return true }

        // BFS with bit-packed visited tracking
        var visited = try! Bit.Array(count: count)
        var queue = [Graph.Node<Tag>]()
        var queueIndex = 0

        visited[source.rawValue] = true
        queue.append(source)

        while queueIndex < queue.count {
            let node = queue[queueIndex]
            queueIndex += 1

            let payload = graph.storage[node.rawValue]
            for adjacent in extract.adjacent(payload) {
                if adjacent == target {
                    return true
                }
                if !visited[adjacent.rawValue] {
                    visited[adjacent.rawValue] = true
                    queue.append(adjacent)
                }
            }
        }

        return false
    }
}
