public import Bit_Vector_Primitives
public import Buffer_Linear_Primitive
public import Column_Primitives
public import Hash_Indexed_Primitive
public import Set_Ordered_Primitives
public import Set_Primitives
public import Shared_Primitive
public import Stack_Primitives
public import Tagged_Collection_Primitives
public import Tagged_Primitives
public import Vector_Primitives

extension Graph.Sequential.Analyze {
    /// Nodes unreachable from roots.
    ///
    /// Uses `Stack` for DFS and `Bit.Array` for visited tracking.
    ///
    /// - Parameter roots: Starting nodes for reachability analysis.
    /// - Returns: Ordered set of nodes not reachable from any root.
    /// - Complexity: O(V + E)
    @inlinable
    public func dead(from roots: some Swift.Sequence<Graph.Node<Tag>>) -> Set_Primitives.Set<Hash.Indexed<Column.Heap<Graph.Node<Tag>>>>.Ordered {
        let count = graph.count
        var result = Set_Primitives.Set<Hash.Indexed<Column.Heap<Graph.Node<Tag>>>>.Ordered()

        guard count > .zero else { return result }

        // Mark all reachable nodes using DFS
        let visited = Bit.Vector(capacity: count.retag(Bit.self))
        var stack = Stack<Graph.Node<Tag>>()

        // Add all valid roots to the stack
        for root in roots {
            let idx = root.retag(Bit.self)
            if root < count && !visited[idx] {
                stack.push(root)
            }
        }

        // DFS to mark reachable nodes
        while let node = stack.pop() {
            let idx = node.retag(Bit.self)
            guard !visited[idx] else { continue }
            visited[idx] = true

            let payload = graph.storage[node]
            for adjacent in extract.adjacent(payload) {
                let adjIdx = adjacent.retag(Bit.self)
                if !visited[adjIdx] {
                    stack.push(adjacent)
                }
            }
        }

        // Collect unvisited nodes as dead
        for node in graph.nodes {
            let idx = node.retag(Bit.self)
            if !visited[idx] {
                result.insert(node)
            }
        }

        return result
    }
}
