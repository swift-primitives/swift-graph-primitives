public import Buffer_Linear_Primitive
public import Column_Primitives
public import Graph_Primitives
public import Hash_Indexed_Primitive
import Set_Ordered_Primitives
public import Set_Primitives

/// Convenience for constructing `Set.Ordered` from node values in tests.
///
/// Spelled against the W5 `Set<S>.Ordered` surface: the ordered set is generic
/// over its ORDERED HASHED column, so the helper pins the move-only
/// `Hash.Indexed<Column.Heap<E>>` column and funnels the variadic elements
/// through `insert`.
extension Set_Primitives.Set where S: ~Copyable {
    public static func ordered<E: Hash.Key>(_ elements: E...) -> Set_Primitives.Set<S>.Ordered
    where S == Hash.Indexed<Column.Heap<E>> {
        var set = Set_Primitives.Set<S>.Ordered()
        for element in elements {
            _ = set.insert(element)
        }
        return set
    }
}
