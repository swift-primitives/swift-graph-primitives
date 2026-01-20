public import Identity_Primitives

extension Graph.Sequential.Analyze {
    /// Whether the graph contains any cycles reachable from the given roots.
    ///
    /// - Parameter roots: The nodes to start cycle detection from.
    /// - Returns: `true` if a cycle is detected, `false` otherwise.
    /// - Complexity: O(V + E)
    @inlinable
    public func hasCycles(from roots: some Sequence<Graph.Node<Tag>>) -> Bool {
        graph.traverse.topological(from: roots, using: extract).hasCycles
    }

    /// Whether the graph contains any cycles reachable from a single root.
    ///
    /// - Parameter root: The node to start cycle detection from.
    /// - Returns: `true` if a cycle is detected, `false` otherwise.
    /// - Complexity: O(V + E)
    @inlinable
    public func hasCycles(from root: Graph.Node<Tag>) -> Bool {
        hasCycles(from: CollectionOfOne(root))
    }

    /// Whether the graph contains any cycles.
    ///
    /// - Returns: `true` if a cycle is detected, `false` otherwise.
    /// - Complexity: O(V + E)
    @inlinable
    public func hasCycles() -> Bool {
        graph.traverse.topological(using: extract).hasCycles
    }
}
