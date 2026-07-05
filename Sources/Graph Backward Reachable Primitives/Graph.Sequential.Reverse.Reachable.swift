public import Bit_Vector_Primitives
public import Buffer_Linear_Primitive
public import Column_Primitives
public import Hash_Indexed_Primitive
public import Set_Ordered_Primitives
// Hoisted carrier `__SetOrdered` spelled directly ([DS-025]/[DS-028]); not surfaced through the umbrella @_exported import.
public import Set_Ordered_Primitive
public import Set_Primitives
public import Ownership_Shared_Primitive
public import Stack_Primitives
public import Tagged_Collection_Primitives
public import Tagged_Primitives
import Vector_Primitives

extension Graph.Sequential.Reverse {
    /// Nodes that can reach the target (backward reachability).
    ///
    /// Uses `Stack` for DFS traversal and `Bit.Array` for visited tracking.
    ///
    /// - Parameter target: The target node.
    /// - Returns: Ordered set of nodes that can reach the target, including the target itself.
    /// - Complexity: O(V + E)
    @inlinable
    public func reachable(to target: Graph.Node<Tag>) -> __SetOrdered<Hash.Indexed<Column.Heap<Graph.Node<Tag>>>> {
        let count = graph.count
        var result = __SetOrdered<Hash.Indexed<Column.Heap<Graph.Node<Tag>>>>()

        guard count > .zero else { return result }

        // Validate target
        guard target < count else { return result }

        // Build reversed graph and run forward reachability from target
        let reversedGraph = self.reversed()

        // DFS from target on reversed graph
        let visited = Bit.Vector(capacity: count.retag(Bit.self))
        var stack = Stack<Graph.Node<Tag>>()

        stack.push(target)

        while let node = stack.pop() {
            let idx = node.retag(Bit.self)
            guard !visited[idx] else { continue }
            visited[idx] = true
            result.insert(node)

            let payload = reversedGraph.storage[node]
            for adjacent in payload.adjacent {
                let adjIdx = adjacent.retag(Bit.self)
                if !visited[adjIdx] {
                    stack.push(adjacent)
                }
            }
        }

        return result
    }
}
