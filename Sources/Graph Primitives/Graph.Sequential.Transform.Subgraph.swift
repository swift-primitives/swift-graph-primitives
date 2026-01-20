public import Identity_Primitives

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
    public func subgraph<Adjacent: Sequence<Graph.Node<Tag>>>(
        inducedBy nodes: Set<Graph.Node<Tag>>,
        using remap: Graph.Remappable.Remap<Payload, Tag, Adjacent>
    ) -> Graph.Sequential<Tag, Payload>? {
        // Validate all nodes are within bounds
        for node in nodes {
            guard node.rawValue >= 0 && node.rawValue < graph.storage.count else {
                return nil
            }
        }

        // Build old-to-new index mapping
        var oldToNew = [Int](repeating: -1, count: graph.storage.count)
        var sortedNodes = [Graph.Node<Tag>]()
        sortedNodes.reserveCapacity(nodes.count)

        for node in nodes {
            sortedNodes.append(node)
        }
        // Sort by raw value to ensure deterministic ordering
        sortedNodes.sort { $0.rawValue < $1.rawValue }

        for (newIndex, node) in sortedNodes.enumerated() {
            oldToNew[node.rawValue] = newIndex
        }

        // Create new storage with remapped payloads
        var newStorage = [Payload]()
        newStorage.reserveCapacity(nodes.count)

        for node in sortedNodes {
            let oldPayload = graph.storage[node.rawValue]

            // Remap node references, using -1 marker for nodes not in subgraph
            // The remap will transform the nodes, then we filter by checking if result is valid
            let remappedPayload = remap.mapNodes(oldPayload) { oldNode in
                let newIdx = oldToNew[oldNode.rawValue]
                if newIdx >= 0 {
                    return Graph.Node<Tag>(rawValue: newIdx)
                } else {
                    // Mark with -1 to indicate this edge should be filtered
                    return Graph.Node<Tag>(rawValue: -1)
                }
            }

            newStorage.append(remappedPayload)
        }

        return Graph.Sequential<Tag, Payload>(storage: newStorage)
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
    public func subgraph(inducedBy nodes: Set<Graph.Node<Tag>>) -> Graph.Sequential<Tag, Payload>? {
        // Validate all nodes are within bounds
        for node in nodes {
            guard node.rawValue >= 0 && node.rawValue < graph.storage.count else {
                return nil
            }
        }

        // Build old-to-new index mapping
        var oldToNew = [Int](repeating: -1, count: graph.storage.count)
        var sortedNodes = [Graph.Node<Tag>]()
        sortedNodes.reserveCapacity(nodes.count)

        for node in nodes {
            sortedNodes.append(node)
        }
        // Sort by raw value to ensure deterministic ordering
        sortedNodes.sort { $0.rawValue < $1.rawValue }

        for (newIndex, node) in sortedNodes.enumerated() {
            oldToNew[node.rawValue] = newIndex
        }

        // Create new storage with filtered and remapped adjacency
        var newStorage = [Graph.Adjacency.List<Tag>]()
        newStorage.reserveCapacity(nodes.count)

        for node in sortedNodes {
            let oldPayload = graph.storage[node.rawValue]

            // Filter to only include edges where target is in the subgraph, then remap
            var newAdjacent = [Graph.Node<Tag>]()
            for adjacent in oldPayload.adjacent {
                let newIdx = oldToNew[adjacent.rawValue]
                if newIdx >= 0 {
                    newAdjacent.append(Graph.Node<Tag>(rawValue: newIdx))
                }
            }

            newStorage.append(Graph.Adjacency.List(adjacent: newAdjacent))
        }

        return Graph.Sequential<Tag, Payload>(storage: newStorage)
    }
}
