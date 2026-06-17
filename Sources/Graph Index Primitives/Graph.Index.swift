// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Index_Primitives

extension Graph {
    /// Type-safe index for graph node positions.
    ///
    /// Uses `Index<Tag>` where Tag is the phantom type distinguishing
    /// different graph instances. This provides compile-time safety
    /// preventing cross-graph index confusion.
    ///
    /// ## Relationship to Graph.Node
    ///
    /// `Graph.Index<Tag>` provides the typed index infrastructure.
    /// `Graph.Node<Tag>` is the higher-level type that may include
    /// additional graph-specific semantics.
    ///
    /// ## Example
    ///
    /// ```swift
    /// enum CFGTag {}
    /// enum DFGTag {}
    ///
    /// let cfgIdx: Graph.Index<CFGTag> = 0
    /// let dfgIdx: Graph.Index<DFGTag> = 0
    /// // cfgIdx == dfgIdx  // Does not compile - different types
    /// ```
    public typealias Index<Tag: ~Copyable & ~Escapable> = Index_Primitives.Index<Tag>
}
