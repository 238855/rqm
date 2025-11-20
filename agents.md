# AI Development Agents Guide

This document provides guidance for AI agents (like Claude, GitHub Copilot, Cursor, etc.) working on the RQM project.

## Project Mission

Build a requirements management system that treats requirements as first-class code artifacts, enabling version control, automated validation, and powerful visualization of complex requirement hierarchies.

## Core Principles

1. **Requirements as Code**: YAML files are the source of truth
2. **Type Safety**: Strong typing across all languages (Rust, Go, TypeScript)
3. **Graph Theory**: Requirements form a directed graph with potential cycles
4. **Validation First**: All input must validate against schema before processing
5. **Developer Experience**: CLI and UI should be intuitive and fast

## Architecture Overview

### Data Flow

```
YAML Files → Rust Parser → Validated Graph → Go CLI / Web UI
     ↓            ↓              ↓                  ↓
  Schema     Type-safe      Cycle          User Interface
Validation   Structures    Detection
```

### Component Responsibilities

**Rust Core (`rust-core/`)**

- YAML parsing and deserialization
- Schema validation using JSON Schema
- Graph construction and cycle detection
- Core business logic and algorithms
- Provides C FFI for Go integration (future)

**Go CLI (`go-cli/`)**

- User-facing command-line interface
- File system operations
- Output formatting (JSON, table, tree)
- Integration with Rust core (initially via process spawning)

**Web UI (`web-ui/`)**

- Interactive graph visualization
- Requirement browsing and search
- Visual cycle detection warnings
- Export capabilities

## Critical Implementation Details

### Circular Reference Strategy

The system MUST handle circular references without infinite loops. Implementation approaches:

1. **Traversal Level**: Track visited nodes in a `HashSet<RequirementId>`
2. **Depth Limiting**: Maximum depth parameter for recursive operations
3. **Lazy Loading**: Load requirement details on-demand, not eagerly
4. **Visual Indicators**: UI shows cycle warnings without breaking

Example pattern:

```rust
fn traverse(req: &Requirement, visited: &mut HashSet<String>, depth: usize) -> Result<()> {
    if visited.contains(&req.summary) || depth > MAX_DEPTH {
        return Ok(()); // Stop traversal
    }
    visited.insert(req.summary.clone());
    // Process requirement
    for child in &req.requirements {
        traverse(child, visited, depth + 1)?;
    }
    Ok(())
}
```

### Schema Design

The JSON Schema must support:

- Inline requirement definitions
- Reference-based requirements (just a summary string)
- Top-level alias definitions
- Flexible owner formats

### Error Handling Philosophy

- **Rust**: Use `Result<T, Error>` with custom error types
- **Go**: Return errors explicitly, don't panic
- **TypeScript**: Use type-safe error boundaries

## Common Patterns

### Adding a New Field to Requirements

1. Update `schema.json`:

```json
{
  "properties": {
    "new_field": {
      "type": "string",
      "description": "Description of new field"
    }
  }
}
```

2. Update Rust struct:

```rust
#[derive(Debug, Deserialize, Serialize)]
pub struct Requirement {
    // existing fields...
    #[serde(skip_serializing_if = "Option::is_none")]
    pub new_field: Option<String>,
}
```

3. Update Go struct:

```go
type Requirement struct {
    // existing fields...
    NewField string `json:"new_field,omitempty" yaml:"new_field,omitempty"`
}
```

4. Update TypeScript interface:

```typescript
interface Requirement {
  // existing fields...
  newField?: string;
}
```

### Testing Circular References

Always include tests for:

- Simple cycle (A → B → A)
- Complex cycle (A → B → C → A)
- Self-reference (A → A)
- Multiple paths to same node (diamond pattern)

## Integration Points

### Rust ↔ Go

Current approach: Go spawns Rust binary as subprocess
Future approach: Use Rust C FFI with `cgo`

### Web UI ↔ Backend

Current approach: Load YAML files directly in browser
Future approach: REST API served by Go CLI

## Performance Considerations

- YAML parsing should be lazy when possible
- Graph algorithms should be O(V + E) where feasible
- UI should virtualize large requirement trees
- Cache validation results within a session

## Security Considerations

- Sanitize file paths to prevent directory traversal
- Validate YAML size limits to prevent DoS
- Escape user content in web UI to prevent XSS
- Don't execute arbitrary code from YAML files

## Documentation Standards

### Code Documentation

- Rust: Use `///` for public items, `//!` for modules
- Go: Use `//` comments above declarations
- TypeScript: Use JSDoc `/** */` for exported items

### File Headers

All source files should include:

```
// RQM - Requirements Management in Code
// Copyright (c) 2025
// SPDX-License-Identifier: MIT
```

## Development Workflow

### Before Committing

1. Run language-specific formatters
2. Run linters (clippy, golangci-lint, eslint)
3. Run all tests
4. Update relevant documentation
5. Check that examples still work

### Version Bumping

- Use semantic versioning
- Update version in: Cargo.toml, go.mod, package.json, README.md
- Create git tag matching version

## AI Agent Specific Guidance

### When Writing Code

- Respect existing patterns in the codebase
- Add tests for new functionality
- Consider edge cases (empty files, malformed YAML, cycles)
- Update documentation inline with code changes

### When Debugging

- Check schema validation first
- Verify file paths are correct
- Look for cycle detection issues
- Check error propagation chain

### When Refactoring

- Ensure backward compatibility for YAML format
- Update all three components if changing shared concepts
- Add migration guide if breaking changes necessary

### When Optimizing

- Profile before optimizing
- Document performance characteristics
- Add benchmarks for critical paths

## Quick Reference

### Build Commands

```bash
# Rust
cd rust-core && cargo build --release

# Go
cd go-cli && go build -o rqm

# Web UI
cd web-ui && npm run build
```

### Test Commands

```bash
# Rust
cd rust-core && cargo test

# Go
cd go-cli && go test ./...

# Web UI
cd web-ui && npm test
```

### Format Commands

```bash
# Rust
cd rust-core && cargo fmt

# Go
cd go-cli && go fmt ./...

# Web UI
cd web-ui && npm run format
```

## Resources

- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [JSON Schema](https://json-schema.org/)
- [YAML Spec](https://yaml.org/spec/)

---

_This is a living document. Update as the project evolves._
