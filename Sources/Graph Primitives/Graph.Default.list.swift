extension Graph.Default {
    /// Default value factory for the canonical `List` payload type.
    /// Per [API-NAME-004]: static constants are direct properties, not nested.
    @inlinable
    public static func list<Tag>() -> Value<Graph.Adjacency.List<Tag>> {
        Value(Graph.Adjacency.List(adjacent: []))
    }
}
