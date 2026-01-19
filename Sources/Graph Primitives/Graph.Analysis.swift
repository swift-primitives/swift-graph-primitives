public import Identity_Primitives

// MARK: - Reachability

extension Graph.Sequential where Payload: Graph.Adjacency, Payload.Tag == Tag {
    /// Returns the set of nodes reachable from the given roots.
    ///
    /// This includes the roots themselves if they are valid nodes.
    ///
    /// - Parameter roots: The nodes to start reachability analysis from.
    /// - Returns: All nodes reachable from any root.
    @inlinable
    public func reachable(
        from roots: some Sequence<Graph.Node<Tag>>
    ) -> Set<Graph.Node<Tag>> {
        let count = storage.count
        guard count > 0 else { return [] }

        // Array-backed visited state: O(1) lookup by node.rawValue
        var visited = [Bool](repeating: false, count: count)
        var stack = [Graph.Node<Tag>]()

        for root in roots {
            let rootIndex = root.rawValue
            if !visited[rootIndex] {
                stack.append(root)
            }
        }

        var result = Set<Graph.Node<Tag>>()
        result.reserveCapacity(count)

        while let node = stack.popLast() {
            let nodeIndex = node.rawValue
            guard !visited[nodeIndex] else { continue }
            visited[nodeIndex] = true
            result.insert(node)

            let payload = storage[nodeIndex]
            for adjacent in payload.adjacent {
                if !visited[adjacent.rawValue] {
                    stack.append(adjacent)
                }
            }
        }

        return result
    }

    /// Returns the set of nodes reachable from a single root.
    ///
    /// - Parameter root: The node to start reachability analysis from.
    /// - Returns: All nodes reachable from the root.
    @inlinable
    public func reachable(from root: Graph.Node<Tag>) -> Set<Graph.Node<Tag>> {
        reachable(from: CollectionOfOne(root))
    }
}

// MARK: - Cycle Detection

extension Graph.Sequential where Payload: Graph.Adjacency, Payload.Tag == Tag {
    /// Whether the graph contains any cycles reachable from the given roots.
    ///
    /// - Parameter roots: The nodes to start cycle detection from.
    /// - Returns: `true` if a cycle is detected, `false` otherwise.
    @inlinable
    public func hasCycles(from roots: some Sequence<Graph.Node<Tag>>) -> Bool {
        topological(from: roots).hasCycles
    }

    /// Whether the graph contains any cycles reachable from a single root.
    ///
    /// - Parameter root: The node to start cycle detection from.
    /// - Returns: `true` if a cycle is detected, `false` otherwise.
    @inlinable
    public func hasCycles(from root: Graph.Node<Tag>) -> Bool {
        hasCycles(from: CollectionOfOne(root))
    }

    /// Whether the graph contains any cycles.
    ///
    /// Checks for cycles among all nodes in the graph.
    ///
    /// - Returns: `true` if a cycle is detected, `false` otherwise.
    @inlinable
    public func hasCycles() -> Bool {
        topological().hasCycles
    }
}

// MARK: - Strongly Connected Components

extension Graph.Sequential where Payload: Graph.Adjacency, Payload.Tag == Tag {
    /// Returns the strongly connected components of the graph.
    ///
    /// Uses Tarjan's algorithm (iterative) to find all SCCs. Components are returned in
    /// reverse topological order (sinks first).
    ///
    /// - Parameter roots: The nodes to start SCC analysis from.
    /// - Returns: An array of SCCs, each being an array of nodes.
    @inlinable
    public func stronglyConnectedComponents(
        from roots: some Sequence<Graph.Node<Tag>>
    ) -> [[Graph.Node<Tag>]] {
        let count = storage.count
        guard count > 0 else { return [] }

        // Array-backed state: O(1) lookup by node.rawValue
        // Use -1 as "not yet visited" sentinel for nodeIndex
        var nodeIndex = [Int](repeating: -1, count: count)
        var lowLink = [Int](repeating: 0, count: count)
        var onStack = [Bool](repeating: false, count: count)

        var index = 0
        var sccStack = [Graph.Node<Tag>]()
        var components = [[Graph.Node<Tag>]]()

        // Call stack frame: (node, iterator, phase)
        // phase: true = entering, false = processing adjacents / leaving
        var callStack: [(node: Graph.Node<Tag>, iterator: Payload.Adjacent.Iterator, phase: Bool)] = []

        for root in roots {
            let rootIndex = root.rawValue
            if nodeIndex[rootIndex] != -1 { continue }

            // Push root
            let rootPayload = storage[rootIndex]
            callStack.append((root, rootPayload.adjacent.makeIterator(), true))

            while !callStack.isEmpty {
                let frameIndex = callStack.count - 1
                let frame = callStack[frameIndex]
                let nodeIdx = frame.node.rawValue

                if frame.phase {
                    // Entering: initialize node
                    nodeIndex[nodeIdx] = index
                    lowLink[nodeIdx] = index
                    index += 1
                    sccStack.append(frame.node)
                    onStack[nodeIdx] = true

                    // Switch to processing phase
                    callStack[frameIndex].phase = false
                }

                // Process adjacents
                var pushedChild = false
                while let adjacent = callStack[frameIndex].iterator.next() {
                    let adjIdx = adjacent.rawValue
                    if nodeIndex[adjIdx] == -1 {
                        // Not yet visited: push and recurse
                        let adjPayload = storage[adjIdx]
                        callStack.append((adjacent, adjPayload.adjacent.makeIterator(), true))
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
                        let w = sccStack.removeLast()
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
    /// - Parameter root: The node to start SCC analysis from.
    /// - Returns: An array of SCCs, each being an array of nodes.
    @inlinable
    public func stronglyConnectedComponents(
        from root: Graph.Node<Tag>
    ) -> [[Graph.Node<Tag>]] {
        stronglyConnectedComponents(from: CollectionOfOne(root))
    }

    /// Returns all strongly connected components in the graph.
    ///
    /// - Returns: An array of SCCs, each being an array of nodes.
    @inlinable
    public func stronglyConnectedComponents() -> [[Graph.Node<Tag>]] {
        stronglyConnectedComponents(from: nodes)
    }
}
