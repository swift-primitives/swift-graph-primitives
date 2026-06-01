/// Toolchain capability gate for the §A9 `Tagged` metadata SIGSEGV.
///
/// `Set<Index>.Ordered.insert` (and any `Set.Ordered` whose element
/// resolves to `Tagged_Primitives.Tagged` — `Graph.Node = Index = Tagged`)
/// SIGSEGVs at runtime on Swift 6.3.x: `Hash.Table` insert forces the
/// element's value-witness table, and `swift_getTypeByMangledName`
/// returns `TypeLookupError("unknown error")` → null-metadata deref.
///
/// This is catalog §A9 (`swift-institute/Research/swift-compiler-bug-catalog.md`,
/// Issues entry `swift-issue-tagged-noncopyable-atomic-metadata-crash`):
/// incomplete `SuppressedAssociatedTypes` codegen on 6.3, fixed by 6.4-dev
/// (the fix travels with the binary, not the runtime). There is no
/// Institute-side code fix — the raw-storage wrapper was reverted on
/// correctness grounds 2026-05-23 — so the affected suites are skipped on
/// the buggy toolchain and run normally once the compiler ships the fix.
public enum Toolchain {
    /// `true` on Swift compilers older than 6.4, where the §A9 `Tagged`
    /// metadata SIGSEGV fires. Used as the predicate for the
    /// `.disabled(if:)` trait on the affected graph suites. `.disabled(if:)`
    /// (not `withKnownIssue`) is required: a SIGSEGV kills the test runner
    /// before swift-testing can register a known issue, so only skipping the
    /// body yields a clean run on 6.3.x.
    public static var hasTaggedMetadataSIGSEGV: Bool {
        #if compiler(<6.4)
        return true
        #else
        return false
        #endif
    }
}
