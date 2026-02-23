public import Identity_Primitives
public import Bit_Vector_Primitives
public import Array_Primitives
public import Queue_Primitives

extension Graph.Sequential.Path {
    /// Whether a path exists from source to target.
    ///
    /// Uses BFS for traversal and `Bit.Vector` for visited tracking.
    ///
    /// - Parameters:
    ///   - source: Starting node.
    ///   - target: Destination node.
    /// - Returns: `true` if a path exists, `false` otherwise.
    /// - Complexity: O(V + E)
    @inlinable
    public func exists(from source: Graph.Node<Tag>, to target: Graph.Node<Tag>) -> Bool {
        let count = graph.count
        guard count > .zero else { return false }

        // Validate nodes
        guard source < count else { return false }
        guard target < count else { return false }

        // Same node is trivially reachable
        if source == target { return true }

        // BFS with bit-packed visited tracking
        let visited = Bit.Vector(capacity: count.retag(Bit.self))
        var queue = Queue<Graph.Node<Tag>>()

        visited[source.retag(Bit.self)] = true
        queue.enqueue(source)

        while let node = queue.dequeue() {
            let payload = graph.storage[node]
            for adjacent in extract.adjacent(payload) {
                if adjacent == target {
                    return true
                }
                let adjIdx = adjacent.retag(Bit.self)
                if !visited[adjIdx] {
                    visited[adjIdx] = true
                    queue.enqueue(adjacent)
                }
            }
        }

        return false
    }
}
