public import Identity_Primitives
public import Set_Primitives
public import Array_Primitives

extension Graph.Sequential.Transform {
    /// Extracts induced subgraph on specified nodes.
    ///
    /// An induced subgraph keeps only the specified nodes and edges where both endpoints
    /// are in the set. Node references in the result are remapped to new sequential IDs
    /// (0..<result.count).
    ///
    /// ## Invariants
    ///
    /// - **Induced subgraph**: Keeps edges where both endpoints are in `nodes`.
    /// - **Totality**: Returns `nil` if any node in `nodes` is not a valid member of this graph.
    /// - **Remapping**: On success, all adjacency references in returned payload are within `0..<newNodeCount`.
    ///
    /// - Parameters:
    ///   - nodes: Nodes to include in the subgraph.
    ///   - remap: Remap for the payload type.
    /// - Returns: New graph where all adjacency references are within `0..<result.count`,
    ///   or `nil` if any node is not a valid member of this graph.
    /// - Complexity: O(n + m) where n is the number of nodes and m is the total edge count.
    @inlinable
    public func subgraph<Adjacent: Swift.Sequence<Graph.Node<Tag>>>(
        inducedBy nodes: consuming Set_Primitives.Set<Graph.Node<Tag>>.Ordered,
        using remap: Graph.Remappable.Remap<Payload, Tag, Adjacent>
    ) -> Graph.Sequential<Tag, Payload>? {
        let count = graph.count

        // Collect nodes from set
        var sortedNodes = [Graph.Node<Tag>]()
        nodes.forEach { node in
            sortedNodes.append(node)
        }

        // Sort to ensure deterministic ordering
        sortedNodes.sort(by: <)

        // Validate bounds
        for node in sortedNodes {
            guard node < count else { return nil }
        }

        // Build old-to-new index mapping
        var oldToNew = Array<Int>.Fixed.Indexed<Tag>(repeating: -1, count: count)
        for (newIndex, node) in sortedNodes.enumerated() {
            oldToNew[node] = newIndex
        }

        // Create new storage with remapped payloads
        var builder = Graph.Sequential<Tag, Payload>.Builder(capacity: count)

        for node in sortedNodes {
            let oldPayload = graph.storage[node]

            // Remap node references, using -1 marker for nodes not in subgraph
            let remappedPayload = remap.mapNodes(oldPayload) { oldNode in
                let newIdx = oldToNew[oldNode]
                if newIdx >= 0 {
                    return Graph.Node<Tag>(__unchecked: (), Ordinal(UInt(newIdx)))
                } else {
                    // Mark with sentinel to indicate this edge should be filtered
                    return Graph.Node<Tag>(__unchecked: (), Ordinal(UInt(bitPattern: -1)))
                }
            }

            _ = builder.allocate(remappedPayload)
        }

        return builder.build()
    }
}

// Convenience for List payload with proper edge filtering
extension Graph.Sequential.Transform where Payload == Graph.Adjacency.List<Tag> {
    /// Extracts induced subgraph on specified nodes using the canonical List type.
    ///
    /// This implementation properly filters edges where the target is not in the subgraph.
    ///
    /// - Parameter nodes: Nodes to include in the subgraph.
    /// - Returns: New graph with remapped adjacency, or `nil` if any node is invalid.
    @inlinable
    public func subgraph(
        inducedBy nodes: consuming Set_Primitives.Set<Graph.Node<Tag>>.Ordered
    ) -> Graph.Sequential<Tag, Payload>? {
        let count = graph.count

        // Collect nodes from set
        var sortedNodes = [Graph.Node<Tag>]()
        nodes.forEach { node in
            sortedNodes.append(node)
        }

        // Sort to ensure deterministic ordering
        sortedNodes.sort(by: <)

        // Validate bounds
        for node in sortedNodes {
            guard node < count else { return nil }
        }

        // Build old-to-new index mapping
        var oldToNew = Array<Int>.Fixed.Indexed<Tag>(repeating: -1, count: count)
        for (newIndex, node) in sortedNodes.enumerated() {
            oldToNew[node] = newIndex
        }

        // Create new storage with filtered and remapped adjacency
        var builder = Graph.Sequential<Tag, Graph.Adjacency.List<Tag>>.Builder(capacity: count)

        for node in sortedNodes {
            let oldPayload = graph.storage[node]

            // Filter to only include edges where target is in the subgraph, then remap
            var newAdjacent = [Graph.Node<Tag>]()
            for adjacent in oldPayload.adjacent {
                let newIdx = oldToNew[adjacent]
                if newIdx >= 0 {
                    newAdjacent.append(Graph.Node<Tag>(__unchecked: (), Ordinal(UInt(newIdx))))
                }
            }

            _ = builder.allocate(Graph.Adjacency.List(adjacent: newAdjacent))
        }

        return builder.build()
    }
}
