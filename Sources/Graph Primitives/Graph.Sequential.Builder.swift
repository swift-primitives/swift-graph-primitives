public import Identity_Primitives

extension Graph.Sequential {
    /// Mutable builder for constructing graphs.
    ///
    /// Use `Builder` to allocate nodes with payloads, then call `build()` to
    /// produce an immutable `Sequential` graph.
    ///
    /// ## Example
    ///
    /// ```swift
    /// enum Tag {}
    /// var builder = Graph.Sequential<Tag, Int>.Builder()
    /// let a = builder.allocate(10)
    /// let b = builder.allocate(20)
    /// let graph = builder.build()
    /// ```
    public struct Builder: ~Copyable {
        @usableFromInline
        var storage: [Payload]

        /// Creates an empty builder.
        @inlinable
        public init() {
            self.storage = []
        }

        /// Creates a builder with reserved capacity.
        @inlinable
        public init(capacity: Int) {
            self.storage = []
            self.storage.reserveCapacity(capacity)
        }

        /// The number of nodes allocated so far.
        @inlinable
        public var count: Int { storage.count }

        /// Allocates a new node with the given payload.
        ///
        /// - Returns: The identity of the newly allocated node.
        @inlinable
        public mutating func allocate(_ payload: Payload) -> Graph.Node<Tag> {
            let id = Graph.Node<Tag>(storage.count)
            storage.append(payload)
            return id
        }

        /// Accesses the payload for a given node.
        ///
        /// - Precondition: The node must have been allocated by this builder.
        @inlinable
        public subscript(node: Graph.Node<Tag>) -> Payload {
            get { storage[node.rawValue] }
            set { storage[node.rawValue] = newValue }
        }

        /// Builds an immutable graph from the allocated nodes.
        ///
        /// This consumes the builder.
        @inlinable
        public consuming func build() -> Graph.Sequential<Tag, Payload> {
            Graph.Sequential(storage: storage)
        }
    }
}

// MARK: - Hole Support

extension Graph.Sequential.Builder where Payload: Graph.Defaultable {
    /// Allocates a new node with a default (hole) payload.
    ///
    /// Use this when the payload will be filled in later via `fill(_:with:)`.
    ///
    /// - Returns: The identity of the newly allocated node.
    @inlinable
    public mutating func allocateHole() -> Graph.Node<Tag> {
        allocate(.graphDefault)
    }

    /// Fills a previously allocated hole with a payload.
    ///
    /// - Parameters:
    ///   - node: The node to fill.
    ///   - payload: The payload to assign.
    @inlinable
    public mutating func fill(_ node: Graph.Node<Tag>, with payload: Payload) {
        storage[node.rawValue] = payload
    }
}
