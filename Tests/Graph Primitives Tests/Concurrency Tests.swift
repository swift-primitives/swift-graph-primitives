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

import Graph_Primitives_Test_Support
import Testing

// W3 rider — GRAPH's own composition under concurrency (arc-1,
// GOAL-tower-arc-shared-soundness §W3): the W5-2 migration (`827aea6`) stores
// payloads in `Tagged<Tag, Array<Payload>.Shared>` behind an
// immutable-`let` read-side bridge — `Graph.Sequential`'s Sendable is the
// CHECKED conditional chain (Graph.Sequential.swift:94), not an @unchecked
// assertion. The adversarial surface is therefore pure concurrent BORROWING:
// many tasks traversing one frozen graph (reads through the shared boxes) while
// sibling copies of the graph value churn retain/release on those same boxes
// mid-traversal. No mutation exists post-build; no detach traffic can occur —
// the postcondition is bit-exact traversal stability against sequential
// references under maximal read/refcount contention.

private enum StormTag {}

private struct StormPayload: Sendable {
    let id: Int
    let successors: [Graph.Node<StormTag>]
}

extension StormPayload {
    static var extract: Graph.Adjacency.Extract<StormPayload, StormTag, [Graph.Node<StormTag>]> {
        Graph.Adjacency.Extract { $0.successors }
    }
}

/// Layered DAG, built bottom-up: every node in layer L points at every node in
/// layer L+1; a single root tops the stack.
///
/// Deterministic ids and successor order make every traversal order a fixed reference.
private func buildLayeredGraph(
    layers: Int,
    width: Int
) -> (graph: Graph.Sequential<StormTag, StormPayload>, root: Graph.Node<StormTag>) {
    var builder = Graph.Sequential<StormTag, StormPayload>.Builder()
    var previous: [Graph.Node<StormTag>] = []
    var id = 0
    for _ in 0..<layers {
        var current: [Graph.Node<StormTag>] = []
        for _ in 0..<width {
            current.append(builder.allocate(StormPayload(id: id, successors: previous)))
            id += 1
        }
        previous = current
    }
    let root = builder.allocate(StormPayload(id: id, successors: previous))
    return (builder.build(), root)
}

private func depthOrder(
    _ graph: Graph.Sequential<StormTag, StormPayload>,
    from root: Graph.Node<StormTag>
) -> [Int] {
    var iter = graph.traverse.first(using: StormPayload.extract).depth(from: root)
    var visited: [Int] = []
    while let element = iter.next() { visited.append(element.payload.id) }
    return visited
}

private func breadthOrder(
    _ graph: Graph.Sequential<StormTag, StormPayload>,
    from root: Graph.Node<StormTag>
) -> [Int] {
    var iter = graph.traverse.first(using: StormPayload.extract).breadth(from: root)
    var visited: [Int] = []
    while let element = iter.next() { visited.append(element.payload.id) }
    return visited
}

@Suite("Graph concurrency (W3 rider)")
struct GraphConcurrencyTests {

    @Test(arguments: [4, 16])
    func `concurrent traversals are bit-exact against the sequential references`(width: Int) async {
        let (graph, root) = buildLayeredGraph(layers: 6, width: 5)
        let depthReference = depthOrder(graph, from: root)
        let breadthReference = breadthOrder(graph, from: root)
        #expect(depthReference.count == 31)  // 6×5 + root, each exactly once
        #expect(breadthReference.count == 31)
        let outcomes = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for t in 0..<width {
                group.addTask {
                    var good = true
                    for _ in 0..<25 {
                        if t % 2 == 0 {
                            good = good && (depthOrder(graph, from: root) == depthReference)
                        } else {
                            good = good && (breadthOrder(graph, from: root) == breadthReference)
                        }
                    }
                    return good
                }
            }
            var out: [Bool] = []
            for await ok in group { out.append(ok) }
            return out
        }
        #expect(outcomes.count == width)
        #expect(outcomes.allSatisfy { $0 })
    }

    @Test
    func `traversals stay exact while sibling copies churn the boxes' refcounts`() async {
        let (graph, root) = buildLayeredGraph(layers: 5, width: 4)
        let depthReference = depthOrder(graph, from: root)
        let breadthReference = breadthOrder(graph, from: root)
        let outcomes = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for _ in 0..<6 {
                group.addTask {  // traversal lane
                    var good = true
                    for _ in 0..<30 {
                        good =
                            good && (depthOrder(graph, from: root) == depthReference)
                            && (breadthOrder(graph, from: root) == breadthReference)
                    }
                    return good
                }
            }
            for _ in 0..<6 {
                group.addTask {  // copy-churn lane: retain/release
                    var good = true  // storms on the SAME shared boxes
                    for _ in 0..<150 {
                        let copy = graph  // retains every column box
                        var iter = copy.traverse.first(using: StormPayload.extract).depth(from: root)
                        good = good && (iter.next()?.payload.id == depthReference[0])
                    }  // copy dies: releases every box
                    return good
                }
            }
            var out: [Bool] = []
            for await ok in group { out.append(ok) }
            return out
        }
        #expect(outcomes.count == 12)
        #expect(outcomes.allSatisfy { $0 })
        // the source graph is untouched by the storm — same references hold after
        let depthAfter = depthOrder(graph, from: root)
        #expect(depthAfter == depthReference)
    }
}
