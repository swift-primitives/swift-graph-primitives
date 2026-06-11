public import Buffer_Linear_Bounded_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives
public import Column_Primitives
public import Fixed_Primitives
public import Hash_Indexed_Primitive
public import Set_Ordered_Primitives
public import Set_Primitives
public import Shared_Primitive
public import Tagged_Collection_Primitives
public import Tagged_Primitives

extension Graph.Sequential.Transform {
    /// Extracts induced subgraph on specified nodes.
    ///
    /// All edges in each included node's payload must point to other included nodes.
    /// Node references in the result are remapped to new sequential IDs (0..<result.count).
    ///
    /// ## Invariants
    ///
    /// - **Closed subgraph**: All adjacency references in included payloads must target included nodes.
    /// - **Totality**: Returns `nil` if any node in `nodes` is out of bounds, or if any edge
    ///   targets a node outside `nodes`.
    /// - **Remapping**: On success, all adjacency references in returned payload are within `0..<newNodeCount`.
    ///
    /// For payloads where edge filtering is needed (dropping edges to excluded nodes),
    /// use the `Adjacency.List` convenience overload or implement filtering in a custom `Remap`.
    ///
    /// - Parameters:
    ///   - nodes: Nodes to include in the subgraph.
    ///   - remap: Remap for the payload type.
    /// - Returns: New graph where all adjacency references are within `0..<result.count`,
    ///   or `nil` if any node is out of bounds or any edge targets a node outside `nodes`.
    /// - Complexity: O(n + m) where n is the number of nodes and m is the total edge count.
    @inlinable
    public func subgraph<Adjacent: Swift.Sequence<Graph.Node<Tag>>>(
        inducedBy nodes: consuming Set_Primitives.Set<Hash.Indexed<Column.Heap<Graph.Node<Tag>>>>.Ordered,
        using remap: Graph.Remappable.Remap<Payload, Tag, Adjacent>
    ) -> Graph.Sequential<Tag, Payload>? {
        let count = graph.count

        // Collect nodes from set via the borrowing `Iterable.forEach`.
        // `Set.Ordered` no longer conforms to `Swift.Sequence` (the
        //   span-primitive iteration family is `~Copyable, ~Escapable`
        //   end-to-end after the SE-0516 migration), so `for node in nodes`
        //   over the dropped stdlib conformance is no longer available.
        //   The current `Iterable.forEach` is the borrowing span-primitive
        //   (`Iterator.Chunk`) iteration path — distinct from the old
        //   `Sequence.\`Protocol\`.forEach` / Property.Inout chain that the
        //   EarlyPerfInliner SIGABRT (mangleForDebugInfo HCHCg pattern)
        //   referenced; that chain no longer exists post-SE-0516.
        var sortedNodes = [Graph.Node<Tag>]()
        nodes.forEach { sortedNodes.append($0) }

        // Sort to ensure deterministic ordering
        sortedNodes.sort(by: <)

        // Validate bounds
        for node in sortedNodes {
            guard node < count else { return nil }
        }

        // Build old-to-new index mapping
        var oldToNew = Fixed<Column.Bounded<Int>>(repeating: -1, count: count.retag(Int.self))
        for (newIndex, node) in sortedNodes.enumerated() {
            oldToNew[node.retag(Int.self)] = newIndex
        }

        // Validate that all edges target included nodes
        for node in sortedNodes {
            let payload = graph.storage[node]
            for adjacent in remap.adjacent(payload) {
                guard oldToNew[adjacent.retag(Int.self)] >= 0 else { return nil }
            }
        }

        // Create new storage with remapped payloads
        var builder = Graph.Sequential<Tag, Payload>.Builder(capacity: count)

        for node in sortedNodes {
            let oldPayload = graph.storage[node]

            let remappedPayload = remap.mapNodes(oldPayload) { oldNode in
                Graph.Node<Tag>(_unchecked: Ordinal(UInt(oldToNew[oldNode.retag(Int.self)])))
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
        inducedBy nodes: consuming Set_Primitives.Set<Hash.Indexed<Column.Heap<Graph.Node<Tag>>>>.Ordered
    ) -> Graph.Sequential<Tag, Payload>? {
        let count = graph.count

        // Collect via the borrowing `Iterable.forEach` — see notes on the
        // sibling generic overload above. `Set.Ordered` no longer conforms
        // to `Swift.Sequence`; `Iterable.forEach` is the borrowing
        // span-primitive (`Iterator.Chunk`) iteration path.
        var sortedNodes = [Graph.Node<Tag>]()
        nodes.forEach { sortedNodes.append($0) }

        // Sort to ensure deterministic ordering
        sortedNodes.sort(by: <)

        // Validate bounds
        for node in sortedNodes {
            guard node < count else { return nil }
        }

        // Build old-to-new index mapping
        var oldToNew = Fixed<Column.Bounded<Int>>(repeating: -1, count: count.retag(Int.self))
        for (newIndex, node) in sortedNodes.enumerated() {
            oldToNew[node.retag(Int.self)] = newIndex
        }

        // Create new storage with filtered and remapped adjacency
        var builder = Graph.Sequential<Tag, Graph.Adjacency.List<Tag>>.Builder(capacity: count)

        for node in sortedNodes {
            let oldPayload = graph.storage[node]

            // Filter to only include edges where target is in the subgraph, then remap
            var newAdjacent = [Graph.Node<Tag>]()
            for adjacent in oldPayload.adjacent {
                let newIdx = oldToNew[adjacent.retag(Int.self)]
                if newIdx >= 0 {
                    newAdjacent.append(Graph.Node<Tag>(_unchecked: Ordinal(UInt(newIdx))))
                }
            }

            _ = builder.allocate(Graph.Adjacency.List(adjacent: newAdjacent))
        }

        return builder.build()
    }
}
