extension Graph.Default {
    /// Stores a default "hole" value for a payload type.
    @frozen
    public struct Value<Payload> {
        @usableFromInline
        let _default: Payload

        @inlinable
        public init(_ value: Payload) {
            self._default = value
        }

        @inlinable
        public var value: Payload { _default }
    }
}
