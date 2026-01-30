public import Identity_Primitives
public import Bit_Primitives
public import Heap_Primitives
public import Array_Primitives

extension Graph.Sequential.Path {
    /// Priority queue entry for Dijkstra's algorithm.
    @usableFromInline
    struct Entry: __HeapOrdering, Comparable, Sendable {
        @usableFromInline let node: Graph.Node<Tag>
        @usableFromInline let distance: Int

        @usableFromInline
        init(node: Graph.Node<Tag>, distance: Int) {
            self.node = node
            self.distance = distance
        }

        @usableFromInline
        static func isLessThan(_ lhs: borrowing Entry, _ rhs: borrowing Entry) -> Bool {
            lhs.distance < rhs.distance
        }

        @usableFromInline
        static func < (lhs: Entry, rhs: Entry) -> Bool {
            lhs.distance < rhs.distance
        }

        @usableFromInline
        static func == (lhs: Entry, rhs: Entry) -> Bool {
            lhs.distance == rhs.distance && lhs.node == rhs.node
        }
    }
}

extension Graph.Sequential.Path {
    /// Shortest path by edge weight using Dijkstra's algorithm.
    ///
    /// Uses `Heap` for priority queue operations and `Bit.Array` for visited tracking.
    ///
    /// - Parameters:
    ///   - source: Starting node.
    ///   - target: Destination node.
    ///   - weight: Closure extracting non-negative edge weight from source payload and target node.
    /// - Returns: Tuple of (path, total distance), or `nil` if unreachable.
    /// - Complexity: O((V + E) log V)
    /// - Precondition: All weights must be non-negative.
    @inlinable
    public func weighted(
        from source: Graph.Node<Tag>,
        to target: Graph.Node<Tag>,
        weight: (Payload, Graph.Node<Tag>) -> Int
    ) -> (path: [Graph.Node<Tag>], distance: Int)? {
        let count = graph.count
        guard count > .zero else { return nil }

        // Validate nodes
        guard source < count else { return nil }
        guard target < count else { return nil }

        // Same node is trivially reachable with distance 0
        if source == target { return ([source], 0) }

        // Dijkstra's algorithm with heap-based priority queue
        var heap = Heap<Entry>()
        var visited = Array<Bit>.Vector(count: count.retag(Bit.self))
        var distances = [Int](repeating: Int.max, count: Int(bitPattern: count))
        var predecessors = [Graph.Node<Tag>?](repeating: nil, count: Int(bitPattern: count))

        distances[source.position] = 0
        heap.push(Entry(node: source, distance: 0))

        while let entry = heap.take.min {
            // Skip if already visited (we may have duplicate entries with worse distances)
            let entryIdx = entry.node.retag(Bit.self)
            guard !visited[entryIdx] else { continue }
            visited[entryIdx] = true

            // Found target - reconstruct path
            if entry.node == target {
                return (reconstructWeightedPath(to: target, predecessors: predecessors, source: source), entry.distance)
            }

            let payload = graph.storage[entry.node]
            for adjacent in extract.adjacent(payload) {
                let adjIdx = adjacent.retag(Bit.self)
                guard !visited[adjIdx] else { continue }

                let edgeWeight = weight(payload, adjacent)
                let newDist = entry.distance + edgeWeight

                let adjIntIdx = adjacent.position
                if newDist < distances[adjIntIdx] {
                    distances[adjIntIdx] = newDist
                    predecessors[adjIntIdx] = entry.node
                    heap.push(Entry(node: adjacent, distance: newDist))
                }
            }
        }

        return nil
    }

    /// Reconstructs a path from the predecessors array.
    @usableFromInline
    func reconstructWeightedPath(
        to target: Graph.Node<Tag>,
        predecessors: [Graph.Node<Tag>?],
        source: Graph.Node<Tag>
    ) -> [Graph.Node<Tag>] {
        var path = [Graph.Node<Tag>]()
        var current: Graph.Node<Tag>? = target

        while let node = current {
            path.append(node)
            if node == source { break }
            current = predecessors[node.position]
        }

        path.reverse()
        return path
    }
}
