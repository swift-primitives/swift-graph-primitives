public import Array_Primitives
public import Index_Primitives
public import Tagged_Primitives

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
            self.storage = [Payload]()
        }

        /// Creates a builder with reserved capacity.
        @inlinable
        public init(capacity: Graph.Node<Tag>.Count) {
            self.storage = [Payload](initialCapacity: capacity.retag(Payload.self))
        }

        /// The number of nodes allocated so far.
        @inlinable
        public var count: Graph.Node<Tag>.Count {
            storage.count.retag(Tag.self)
        }

        /// Allocates a new node with the given payload.
        ///
        /// - Returns: The identity of the newly allocated node.
        @inlinable
        public mutating func allocate(_ payload: Payload) -> Graph.Node<Tag> {
            let id = count.map(Ordinal.init)
            storage.append(payload)
            return id
        }

        /// Accesses the payload for a given node.
        ///
        /// - Precondition: The node must have been allocated by this builder.
        @inlinable
        public subscript(node: Graph.Node<Tag>) -> Payload {
            get { storage[node.retag(Payload.self)] }
            set { storage[node.retag(Payload.self)] = newValue }
        }

        /// Builds an immutable graph from the allocated nodes.
        ///
        /// This consumes the builder.
        @inlinable
        public consuming func build() -> Graph.Sequential<Tag, Payload> {
            Graph.Sequential(storage: Array<Payload>.Indexed<Tag>(storage))
        }
    }
}

// MARK: - Hole Support

extension Graph.Sequential.Builder {
    /// Allocates a new node with a default (hole) payload.
    ///
    /// Use this when the payload will be filled in later via `fill(_:with:)`.
    ///
    /// - Parameter default: The default value witness providing the hole value.
    /// - Returns: The identity of the newly allocated node.
    @inlinable
    public mutating func allocateHole(
        using default: Graph.Default.Value<Payload>
    ) -> Graph.Node<Tag> {
        allocate(`default`.value)
    }

    /// Fills a previously allocated hole with a payload.
    ///
    /// - Parameters:
    ///   - node: The node to fill.
    ///   - payload: The payload to assign.
    @inlinable
    public mutating func fill(_ node: Graph.Node<Tag>, with payload: Payload) {
        storage[node.retag(Payload.self)] = payload
    }
}

// Convenience for List payload
extension Graph.Sequential.Builder where Payload == Graph.Adjacency.List<Tag> {
    /// Allocates a new node with an empty adjacency list.
    ///
    /// - Returns: The identity of the newly allocated node.
    @inlinable
    public mutating func allocateHole() -> Graph.Node<Tag> {
        allocateHole(using: Graph.Default.list())
    }
}
