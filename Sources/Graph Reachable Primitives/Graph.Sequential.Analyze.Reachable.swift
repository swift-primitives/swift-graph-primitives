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

extension Graph.Sequential.Analyze {
    /// Returns the set of nodes reachable from the given roots.
    ///
    /// Uses `Stack` for DFS and `Bit.Vector` for visited tracking.
    ///
    /// - Parameter roots: The nodes to start reachability analysis from.
    /// - Returns: Ordered set of all nodes reachable from any root (includes roots themselves).
    /// - Complexity: O(V + E)
    @inlinable
    public func reachable(from roots: some Swift.Sequence<Graph.Node<Tag>>) -> __SetOrdered<Hash.Indexed<Column.Heap<Graph.Node<Tag>>>> {
        let count = graph.count
        // Capacity folds the former post-construction `reserve` into the
        // column-pinned constructor (the W5 `Set<S>.Ordered` surface has no
        // reserve; capacity is fixed at construction or grows on insert).
        var result = __SetOrdered<Hash.Indexed<Column.Heap<Graph.Node<Tag>>>>(
            minimumCapacity: count.retag(Graph.Node<Tag>.self)
        )
        guard count > .zero else { return result }

        let visited = Bit.Vector(capacity: count.retag(Bit.self))
        var stack = Stack<Graph.Node<Tag>>()

        for root in roots {
            let idx = root.retag(Bit.self)
            if root < count && !visited[idx] {
                stack.push(root)
            }
        }

        while let node = stack.pop() {
            let idx = node.retag(Bit.self)
            guard !visited[idx] else { continue }
            visited[idx] = true
            result.insert(node)

            let payload = graph.storage[node]
            for adjacent in extract.adjacent(payload) {
                let adjIdx = adjacent.retag(Bit.self)
                if !visited[adjIdx] {
                    stack.push(adjacent)
                }
            }
        }

        return result
    }

    /// Returns the set of nodes reachable from a single root.
    ///
    /// Uses `Stack` for DFS and `Bit.Vector` for visited tracking.
    ///
    /// - Parameter root: The node to start reachability analysis from.
    /// - Returns: Ordered set of all nodes reachable from the root.
    /// - Complexity: O(V + E)
    @inlinable
    public func reachable(from root: Graph.Node<Tag>) -> __SetOrdered<Hash.Indexed<Column.Heap<Graph.Node<Tag>>>> {
        reachable(from: Swift.CollectionOfOne(root))
    }
}
