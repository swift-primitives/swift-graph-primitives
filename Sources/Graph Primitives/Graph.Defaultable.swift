extension Graph {
    /// A payload type that can represent an unfilled hole.
    ///
    /// Conform to this protocol when payloads need forward references.
    /// The `graphDefault` value represents a placeholder that will be filled
    /// in later during graph construction.
    ///
    /// ## Example
    ///
    /// ```swift
    /// enum Instruction: Graph.Defaultable {
    ///     case operation(Op)
    ///     case hole
    ///
    ///     static var graphDefault: Self { .hole }
    /// }
    /// ```
    public protocol Defaultable {
        /// The default value representing an unfilled hole.
        static var graphDefault: Self { get }
    }
}
