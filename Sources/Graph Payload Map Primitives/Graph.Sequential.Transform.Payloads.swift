public import Vector_Primitives

extension Graph.Sequential.Transform {
    /// Transforms all payloads. Node identities are preserved.
    ///
    /// - Parameter transform: Closure mapping old payloads to new payloads.
    /// - Returns: A new graph with transformed payloads.
    /// - Complexity: O(n) where n is the number of nodes.
    @inlinable
    public func payloads<NewPayload>(
        _ transform: (Payload) -> NewPayload
    ) -> Graph.Sequential<Tag, NewPayload> {
        var builder = Graph.Sequential<Tag, NewPayload>.Builder(capacity: graph.count)
        for node in graph.nodes {
            _ = builder.allocate(transform(graph[node]))
        }
        return builder.build()
    }
}
