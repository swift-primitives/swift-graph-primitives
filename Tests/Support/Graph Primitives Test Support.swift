public import Graph_Primitives
public import Set_Primitives

/// Convenience for constructing `Set.Ordered` from node values in tests.
extension Set_Primitives.Set where Element: Hash_Primitives.Hash.`Protocol` & Copyable {
    public static func ordered(_ elements: Element...) -> Set_Primitives.Set<Element>.Ordered {
        var set = Set_Primitives.Set<Element>.Ordered()
        for element in elements {
            _ = set.insert(element)
        }
        return set
    }
}
