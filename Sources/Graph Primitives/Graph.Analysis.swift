public import Identity_Primitives
public import Stack_Primitives
public import Bit_Primitives

// MARK: - Reachability

extension Graph.Sequential {
    /// Returns the set of nodes reachable from the given roots.
    ///
    /// This includes the roots themselves if they are valid nodes.
    ///
    /// - Parameters:
    ///   - roots: The nodes to start reachability analysis from.
    ///   - extract: The adjacency extract for the payload type.
    /// - Returns: All nodes reachable from any root.
    @inlinable
    public func reachable<Adjacent: Sequence<Graph.Node<Tag>>>(
        from roots: some Sequence<Graph.Node<Tag>>,
        using extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
    ) -> Set<Graph.Node<Tag>> {
        let count = storage.count
        guard count > 0 else { return [] }

        // Bit-packed visited state: O(1) lookup by node.rawValue with 8x memory savings
        var visited = try! Bit.Array(count: count)
        var stack = Stack<Graph.Node<Tag>>()

        for root in roots {
            let rootIndex = root.rawValue
            if !visited[rootIndex] {
                stack.push(root)
            }
        }

        var result = Set<Graph.Node<Tag>>()
        result.reserveCapacity(count)

        while let node = stack.pop() {
            let nodeIndex = node.rawValue
            guard !visited[nodeIndex] else { continue }
            visited[nodeIndex] = true
            result.insert(node)

            let payload = storage[nodeIndex]
            for adjacent in extract.adjacent(payload) {
                if !visited[adjacent.rawValue] {
                    stack.push(adjacent)
                }
            }
        }

        return result
    }

    /// Returns the set of nodes reachable from a single root.
    ///
    /// - Parameters:
    ///   - root: The node to start reachability analysis from.
    ///   - extract: The adjacency extract for the payload type.
    /// - Returns: All nodes reachable from the root.
    @inlinable
    public func reachable<Adjacent: Sequence<Graph.Node<Tag>>>(
        from root: Graph.Node<Tag>,
        using extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
    ) -> Set<Graph.Node<Tag>> {
        reachable(from: CollectionOfOne(root), using: extract)
    }
}

// Convenience for List payload
extension Graph.Sequential where Payload == Graph.Adjacency.List<Tag> {
    /// Returns the set of nodes reachable from the given roots.
    @inlinable
    public func reachable(
        from roots: some Sequence<Graph.Node<Tag>>
    ) -> Set<Graph.Node<Tag>> {
        reachable(from: roots, using: .list)
    }

    /// Returns the set of nodes reachable from a single root.
    @inlinable
    public func reachable(from root: Graph.Node<Tag>) -> Set<Graph.Node<Tag>> {
        reachable(from: CollectionOfOne(root), using: .list)
    }
}

// MARK: - Cycle Detection

extension Graph.Sequential {
    /// Whether the graph contains any cycles reachable from the given roots.
    ///
    /// - Parameters:
    ///   - roots: The nodes to start cycle detection from.
    ///   - extract: The adjacency extract for the payload type.
    /// - Returns: `true` if a cycle is detected, `false` otherwise.
    @inlinable
    public func hasCycles<Adjacent: Sequence<Graph.Node<Tag>>>(
        from roots: some Sequence<Graph.Node<Tag>>,
        using extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
    ) -> Bool {
        traverse.topological(from: roots, using: extract).hasCycles
    }

    /// Whether the graph contains any cycles reachable from a single root.
    ///
    /// - Parameters:
    ///   - root: The node to start cycle detection from.
    ///   - extract: The adjacency extract for the payload type.
    /// - Returns: `true` if a cycle is detected, `false` otherwise.
    @inlinable
    public func hasCycles<Adjacent: Sequence<Graph.Node<Tag>>>(
        from root: Graph.Node<Tag>,
        using extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
    ) -> Bool {
        hasCycles(from: CollectionOfOne(root), using: extract)
    }

    /// Whether the graph contains any cycles.
    ///
    /// - Parameter extract: The adjacency extract for the payload type.
    /// - Returns: `true` if a cycle is detected, `false` otherwise.
    @inlinable
    public func hasCycles<Adjacent: Sequence<Graph.Node<Tag>>>(
        using extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
    ) -> Bool {
        traverse.topological(using: extract).hasCycles
    }
}

// Convenience for List payload
extension Graph.Sequential where Payload == Graph.Adjacency.List<Tag> {
    /// Whether the graph contains any cycles reachable from the given roots.
    @inlinable
    public func hasCycles(from roots: some Sequence<Graph.Node<Tag>>) -> Bool {
        hasCycles(from: roots, using: .list)
    }

    /// Whether the graph contains any cycles reachable from a single root.
    @inlinable
    public func hasCycles(from root: Graph.Node<Tag>) -> Bool {
        hasCycles(from: CollectionOfOne(root), using: .list)
    }

    /// Whether the graph contains any cycles.
    @inlinable
    public func hasCycles() -> Bool {
        hasCycles(using: .list)
    }
}

// MARK: - Strongly Connected Components

extension Graph.Sequential {
    /// Returns the strongly connected components of the graph.
    ///
    /// Uses Tarjan's algorithm (iterative) to find all SCCs. Components are returned in
    /// reverse topological order (sinks first).
    ///
    /// - Parameters:
    ///   - roots: The nodes to start SCC analysis from.
    ///   - extract: The adjacency extract for the payload type.
    /// - Returns: An array of SCCs, each being an array of nodes.
    @inlinable
    public func stronglyConnectedComponents<Adjacent: Sequence<Graph.Node<Tag>>>(
        from roots: some Sequence<Graph.Node<Tag>>,
        using extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
    ) -> [[Graph.Node<Tag>]] {
        let count = storage.count
        guard count > 0 else { return [] }

        // Array-backed state: O(1) lookup by node.rawValue
        // Use -1 as "not yet visited" sentinel for nodeIndex
        var nodeIndex = [Int](repeating: -1, count: count)
        var lowLink = [Int](repeating: 0, count: count)
        // Bit-packed onStack: 8x memory savings
        var onStack = try! Bit.Array(count: count)

        var index = 0
        var sccStack = Stack<Graph.Node<Tag>>()
        var components = [[Graph.Node<Tag>]]()

        // Call stack frame: (node, adjacents as array, current index, phase)
        // phase: true = entering, false = processing adjacents / leaving
        var callStack: [(node: Graph.Node<Tag>, adjacents: [Graph.Node<Tag>], adjIndex: Int, phase: Bool)] = []

        for root in roots {
            let rootIndex = root.rawValue
            if nodeIndex[rootIndex] != -1 { continue }

            // Push root
            let rootPayload = storage[rootIndex]
            let rootAdjacents = Array(extract.adjacent(rootPayload))
            callStack.append((root, rootAdjacents, 0, true))

            while !callStack.isEmpty {
                let frameIndex = callStack.count - 1
                var frame = callStack[frameIndex]
                let nodeIdx = frame.node.rawValue

                if frame.phase {
                    // Entering: initialize node
                    nodeIndex[nodeIdx] = index
                    lowLink[nodeIdx] = index
                    index += 1
                    sccStack.push(frame.node)
                    onStack[nodeIdx] = true

                    // Switch to processing phase
                    callStack[frameIndex].phase = false
                    frame.phase = false
                }

                // Process adjacents
                var pushedChild = false
                while frame.adjIndex < frame.adjacents.count {
                    let adjacent = frame.adjacents[frame.adjIndex]
                    callStack[frameIndex].adjIndex += 1
                    frame.adjIndex += 1

                    let adjIdx = adjacent.rawValue
                    if nodeIndex[adjIdx] == -1 {
                        // Not yet visited: push and recurse
                        let adjPayload = storage[adjIdx]
                        let adjAdjacents = Array(extract.adjacent(adjPayload))
                        callStack.append((adjacent, adjAdjacents, 0, true))
                        pushedChild = true
                        break
                    } else if onStack[adjIdx] {
                        // On stack: update lowLink
                        lowLink[nodeIdx] = min(lowLink[nodeIdx], nodeIndex[adjIdx])
                    }
                    // else: already processed and not on stack, ignore
                }

                if pushedChild {
                    continue
                }

                // All adjacents processed: check for SCC root and pop
                callStack.removeLast()

                if lowLink[nodeIdx] == nodeIndex[nodeIdx] {
                    // Node is SCC root: pop component
                    var component = [Graph.Node<Tag>]()
                    repeat {
                        let w = sccStack.pop()!
                        onStack[w.rawValue] = false
                        component.append(w)
                    } while component.last != frame.node
                    components.append(component)
                }

                // Update parent's lowLink if there is a parent
                if !callStack.isEmpty {
                    let parentIdx = callStack[callStack.count - 1].node.rawValue
                    lowLink[parentIdx] = min(lowLink[parentIdx], lowLink[nodeIdx])
                }
            }
        }

        return components
    }

    /// Returns the strongly connected components reachable from a single root.
    ///
    /// - Parameters:
    ///   - root: The node to start SCC analysis from.
    ///   - extract: The adjacency extract for the payload type.
    /// - Returns: An array of SCCs, each being an array of nodes.
    @inlinable
    public func stronglyConnectedComponents<Adjacent: Sequence<Graph.Node<Tag>>>(
        from root: Graph.Node<Tag>,
        using extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
    ) -> [[Graph.Node<Tag>]] {
        stronglyConnectedComponents(from: CollectionOfOne(root), using: extract)
    }

    /// Returns all strongly connected components in the graph.
    ///
    /// - Parameter extract: The adjacency extract for the payload type.
    /// - Returns: An array of SCCs, each being an array of nodes.
    @inlinable
    public func stronglyConnectedComponents<Adjacent: Sequence<Graph.Node<Tag>>>(
        using extract: Graph.Adjacency.Extract<Payload, Tag, Adjacent>
    ) -> [[Graph.Node<Tag>]] {
        stronglyConnectedComponents(from: nodes, using: extract)
    }
}

// Convenience for List payload
extension Graph.Sequential where Payload == Graph.Adjacency.List<Tag> {
    /// Returns the strongly connected components of the graph.
    @inlinable
    public func stronglyConnectedComponents(
        from roots: some Sequence<Graph.Node<Tag>>
    ) -> [[Graph.Node<Tag>]] {
        stronglyConnectedComponents(from: roots, using: .list)
    }

    /// Returns the strongly connected components reachable from a single root.
    @inlinable
    public func stronglyConnectedComponents(
        from root: Graph.Node<Tag>
    ) -> [[Graph.Node<Tag>]] {
        stronglyConnectedComponents(from: CollectionOfOne(root), using: .list)
    }

    /// Returns all strongly connected components in the graph.
    @inlinable
    public func stronglyConnectedComponents() -> [[Graph.Node<Tag>]] {
        stronglyConnectedComponents(from: nodes, using: .list)
    }
}
