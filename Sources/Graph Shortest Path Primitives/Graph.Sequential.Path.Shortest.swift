public import Bit_Vector_Primitives
public import Buffer_Linear_Bounded_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives
public import Buffer_Ring_Primitive
public import Column_Primitives
public import Fixed_Primitives
public import Queue_Primitives
public import Shared_Primitive
public import Tagged_Collection_Primitives
public import Tagged_Primitives
import Vector_Primitives

extension Graph.Sequential.Path {
    /// Shortest path by hop count using BFS.
    ///
    /// Uses `Queue` for BFS traversal and `Bit.Vector` for visited tracking.
    ///
    /// - Parameters:
    ///   - source: Starting node.
    ///   - target: Destination node.
    /// - Returns: Path from source to target (inclusive), or `nil` if unreachable.
    /// - Complexity: O(V + E)
    @inlinable
    public func shortest(from source: Graph.Node<Tag>, to target: Graph.Node<Tag>) -> [Graph.Node<Tag>]? {
        let count = graph.count
        guard count > .zero else { return nil }

        // Validate nodes
        guard source < count else { return nil }
        guard target < count else { return nil }

        // Same node is trivially reachable
        if source == target { return [source] }

        // BFS with bit-packed visited tracking and predecessor array
        let visited = Bit.Vector(capacity: count.retag(Bit.self))
        var predecessors = Fixed<Column.Bounded<Graph.Node<Tag>?>>(repeating: nil, count: count.retag((Graph.Node<Tag>?).self))
        var queue = Queue<Column.Ring<Graph.Node<Tag>>>()

        visited[source.retag(Bit.self)] = true
        queue.enqueue(source)

        while let node = queue.dequeue() {
            let payload = graph.storage[node]
            for adjacent in extract.adjacent(payload) {
                let adjIdx = adjacent.retag(Bit.self)
                if !visited[adjIdx] {
                    visited[adjIdx] = true
                    predecessors[adjacent.retag((Graph.Node<Tag>?).self)] = node
                    queue.enqueue(adjacent)

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
        predecessors: borrowing Fixed<Column.Bounded<Graph.Node<Tag>?>>,
        source: Graph.Node<Tag>
    ) -> [Graph.Node<Tag>] {
        var path = [Graph.Node<Tag>]()
        var current: Graph.Node<Tag>? = target

        while let node = current {
            path.append(node)
            if node == source { break }
            current = predecessors[node.retag((Graph.Node<Tag>?).self)]
        }

        path.reverse()
        return path
    }
}
