---
name: graph-primitives
description: |
  Graph structure primitives for dependency analysis and traversal.
  ALWAYS apply when working with graph data structures.

layer: implementation

requires:
  - primitives

applies_to:
  - swift
  - swift-primitives
  - swift-graph-primitives
---

# Graph Primitives

Timeless graph substrate for dependency analysis and traversal.

---

## Core Design Decisions

### [GRP-001] Maximalist Extraction

**Statement**: Graph primitives extract maximum reusable graph operations from specific use cases.

### [GRP-002] Dependency Structure

**Statement**: Graph types support directed, weighted, and cyclic graphs.

---

## Cross-References

Full analysis:
- `Research/Analysis - Graph Primitives as Timeless Substrate.md`
- `Research/Analysis - Maximalist Graph Extraction.md`
