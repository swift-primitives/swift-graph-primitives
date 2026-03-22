public import Identity_Primitives
public import Stack_Primitives
internal import Bit_Vector_Primitives
public import Array_Primitives

extension Graph.Sequential.Analyze {
    /// Returns the strongly connected components of the graph.
    ///
    /// Uses Tarjan's algorithm (iterative) with `Stack` and `Bit.Vector`.
    /// Components are returned in reverse topological order (sinks first).
    ///
    /// - Parameter roots: The nodes to start SCC analysis from.
    /// - Returns: An array of SCCs, each being an array of nodes.
    /// - Complexity: O(V + E)
    @inlinable
    public func scc(from roots: some Swift.Sequence<Graph.Node<Tag>>) -> [[Graph.Node<Tag>]] {
        let count = graph.count
        guard count > .zero else { return [] }

        // Array-backed state: O(1) lookup by node
        // Use -1 as "not yet visited" sentinel for nodeIndex
        var nodeIndex = Array<Int>.Fixed.Indexed<Tag>(repeating: -1, count: count)
        var lowLink = Array<Int>.Fixed.Indexed<Tag>(repeating: 0, count: count)
        let onStack = Bit.Vector(capacity: count.retag(Bit.self))

        var index = 0
        var sccStack = Stack<Graph.Node<Tag>>()
        var components = [[Graph.Node<Tag>]]()

        // Call stack frame: (node, adjacents as array, current index, phase)
        // phase: true = entering, false = processing adjacents / leaving
        var callStack: [(node: Graph.Node<Tag>, adjacents: [Graph.Node<Tag>], adjIndex: Int, phase: Bool)] = []

        for root in roots {
            guard root < count else { continue }
            if nodeIndex[root] != -1 { continue }

            // Push root
            let rootPayload = graph.storage[root]
            let rootAdjacents = Swift.Array(extract.adjacent(rootPayload))
            callStack.append((root, rootAdjacents, 0, true))

            while !callStack.isEmpty {
                let frameIndex = callStack.count - 1
                var frame = callStack[frameIndex]
                let node = frame.node

                if frame.phase {
                    // Entering: initialize node
                    nodeIndex[node] = index
                    lowLink[node] = index
                    index += 1
                    sccStack.push(frame.node)
                    onStack[frame.node.retag(Bit.self)] = true

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

                    if nodeIndex[adjacent] == -1 {
                        // Not yet visited: push and recurse
                        let adjPayload = graph.storage[adjacent]
                        let adjAdjacents = Swift.Array(extract.adjacent(adjPayload))
                        callStack.append((adjacent, adjAdjacents, 0, true))
                        pushedChild = true
                        break
                    } else if onStack[adjacent.retag(Bit.self)] {
                        // On stack: update lowLink
                        lowLink[node] = min(lowLink[node], nodeIndex[adjacent])
                    }
                    // else: already processed and not on stack, ignore
                }

                if pushedChild {
                    continue
                }

                // All adjacents processed: check for SCC root and pop
                callStack.removeLast()

                if lowLink[node] == nodeIndex[node] {
                    // Node is SCC root: pop component
                    var component = [Graph.Node<Tag>]()
                    repeat {
                        let w = sccStack.pop()!
                        onStack[w.retag(Bit.self)] = false
                        component.append(w)
                    } while component.last != frame.node
                    components.append(component)
                }

                // Update parent's lowLink if there is a parent
                if !callStack.isEmpty {
                    let parent = callStack[callStack.count - 1].node
                    lowLink[parent] = min(lowLink[parent], lowLink[node])
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
        scc(from: Swift.CollectionOfOne(root))
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
