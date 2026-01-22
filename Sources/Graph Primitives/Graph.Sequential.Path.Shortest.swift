public import Identity_Primitives
public import Bit_Primitives
public import Array_Primitives

extension Graph.Sequential.Path {
    /// Shortest path by hop count using BFS.
    ///
    /// Uses BFS for traversal and `Bit.Array` for visited tracking.
    ///
    /// - Parameters:
    ///   - source: Starting node.
    ///   - target: Destination node.
    /// - Returns: Path from source to target (inclusive), or `nil` if unreachable.
    /// - Complexity: O(V + E)
    @inlinable
    public func shortest(from source: Graph.Node<Tag>, to target: Graph.Node<Tag>) -> [Graph.Node<Tag>]? {
        let count = graph.storage.count
        guard count > 0 else { return nil }

        // Validate nodes
        guard source.position.rawValue >= 0 && source.position.rawValue < count else { return nil }
        guard target.position.rawValue >= 0 && target.position.rawValue < count else { return nil }

        // Same node is trivially reachable
        if source == target { return [source] }

        // BFS with bit-packed visited tracking and predecessor array
        var visited = try! Array<Bit>.Packed(count: count)
        var predecessors = [Graph.Node<Tag>?](repeating: nil, count: count)
        var queue = [Graph.Node<Tag>]()
        var queueIndex = 0

        visited[Bit.Index(source.position)] = true
        queue.append(source)

        while queueIndex < queue.count {
            let node = queue[queueIndex]
            queueIndex += 1

            let payload = graph.storage[node.position.rawValue]
            for adjacent in extract.adjacent(payload) {
                let adjIdx = Bit.Index(adjacent.position)
                if !visited[adjIdx] {
                    visited[adjIdx] = true
                    predecessors[adjacent.position.rawValue] = node
                    queue.append(adjacent)

                    if adjacent == target {
                        // Found target - reconstruct path
                        return reconstructPath(to: target, predecessors: predecessors, source: source)
                    }
                }
            }
        }

        return nil
    }

    /// Reconstructs a path from the predecessors array.
    @usableFromInline
    func reconstructPath(
        to target: Graph.Node<Tag>,
        predecessors: [Graph.Node<Tag>?],
        source: Graph.Node<Tag>
    ) -> [Graph.Node<Tag>] {
        var path = [Graph.Node<Tag>]()
        var current: Graph.Node<Tag>? = target

        while let node = current {
            path.append(node)
            if node == source { break }
            current = predecessors[node.position.rawValue]
        }

        path.reverse()
        return path
    }
}
