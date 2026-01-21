public import Identity_Primitives
public import Stack_Primitives
public import Bit_Primitives
public import Array_Primitives

extension Graph.Sequential.Analyze {
    /// Returns the strongly connected components of the graph.
    ///
    /// Uses Tarjan's algorithm (iterative) with `Stack` and `Bit.Array`.
    /// Components are returned in reverse topological order (sinks first).
    ///
    /// - Parameter roots: The nodes to start SCC analysis from.
    /// - Returns: An array of SCCs, each being an array of nodes.
    /// - Complexity: O(V + E)
    @inlinable
    public func scc(from roots: some Sequence<Graph.Node<Tag>>) -> [[Graph.Node<Tag>]] {
        let count = graph.storage.count
        guard count > 0 else { return [] }

        // Array-backed state: O(1) lookup by node.rawValue
        // Use -1 as "not yet visited" sentinel for nodeIndex
        var nodeIndex = [Int](repeating: -1, count: count)
        var lowLink = [Int](repeating: 0, count: count)
        var onStack = try! Bit.Array(count: count)

        var index = 0
        var sccStack = Stack<Graph.Node<Tag>>()
        var components = [[Graph.Node<Tag>]]()

        // Call stack frame: (node, adjacents as array, current index, phase)
        // phase: true = entering, false = processing adjacents / leaving
        var callStack: [(node: Graph.Node<Tag>, adjacents: [Graph.Node<Tag>], adjIndex: Int, phase: Bool)] = []

        for root in roots {
            let rootIndex = root.rawValue
            if rootIndex < 0 || rootIndex >= count { continue }
            if nodeIndex[rootIndex] != -1 { continue }

            // Push root
            let rootPayload = graph.storage[rootIndex]
            let rootAdjacents = Swift.Array(extract.adjacent(rootPayload))
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
                        let adjPayload = graph.storage[adjIdx]
                        let adjAdjacents = Swift.Array(extract.adjacent(adjPayload))
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
    /// - Parameter root: The node to start SCC analysis from.
    /// - Returns: An array of SCCs, each being an array of nodes.
    /// - Complexity: O(V + E)
    @inlinable
    public func scc(from root: Graph.Node<Tag>) -> [[Graph.Node<Tag>]] {
        scc(from: CollectionOfOne(root))
    }

    /// Returns all strongly connected components in the graph.
    ///
    /// - Returns: An array of SCCs, each being an array of nodes.
    /// - Complexity: O(V + E)
    @inlinable
    public func scc() -> [[Graph.Node<Tag>]] {
        scc(from: graph.nodes)
    }
}
