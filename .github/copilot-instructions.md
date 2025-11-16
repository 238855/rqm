# GitHub Copilot Instructions for RQM

## Project Context

RQM (Requirements Management) is a polyglot monorepo for managing requirements as code. The project consists of:

- **Rust core library** (`rust-core/`) - Core parsing, validation, and graph traversal logic
- **Go CLI** (`go-cli/`) - Command-line interface with `rqm` and `requim` commands
- **React TypeScript Web UI** (`web-ui/`) - Interactive requirement tree visualization

## Code Style & Conventions

### Rust (rust-core/)
- Follow Rust 2021 edition idioms
- Use `cargo fmt` and `cargo clippy` before committing
- Prefer `Result<T, E>` for error handling
- Use `serde` for YAML serialization/deserialization
- Document all public APIs with rustdoc comments
- Write unit tests for all core logic
- Use `thiserror` for custom error types

### Go (go-cli/)
- Follow standard Go formatting (`gofmt`)
- Use `cobra` for CLI structure
- Prefer table-driven tests
- Use context for cancellation and timeouts
- Document exported functions and types
- Error messages should be lowercase and not end with punctuation
- Use structured logging where appropriate

### TypeScript/React (web-ui/)
- Use functional components with hooks
- Follow React best practices and hooks rules
- Use TypeScript strict mode
- Prefer composition over inheritance
- Use descriptive variable and function names
- Organize components by feature
- Use CSS modules or styled-components for styling

## Key Architectural Decisions

### Circular Reference Handling
When working with requirement graphs:
- Always track visited nodes during traversal
- Implement depth limits for recursive operations
- Use reference IDs rather than deep cloning
- Test circular reference scenarios explicitly

### YAML Schema
- All YAML files must validate against the JSON Schema in `docs/schema.json`
- Summaries must be unique within a file
- Owner references can be email, GitHub username, or alias
- Aliases are defined at the top-level configuration

### Monorepo Management
- Each subproject has its own build/test configuration
- Shared types/interfaces should be documented
- Version numbers should stay synchronized across components
- CI/CD handles all three components

## Testing Guidelines

- **Rust**: Unit tests in the same file, integration tests in `tests/`
- **Go**: Tests in `*_test.go` files, use table-driven tests
- **React**: Use React Testing Library, test user interactions not implementation

## Common Tasks

### Adding a New Requirement Field
1. Update the JSON Schema in `docs/schema.json`
2. Update Rust types in `rust-core/src/types.rs`
3. Update Go types if needed for CLI display
4. Update TypeScript interfaces in `web-ui/src/types/`
5. Update example files in `examples/`
6. Update documentation

### Adding a New CLI Command
1. Create command in `go-cli/cmd/`
2. Wire it up in the root command
3. Add tests in `*_test.go`
4. Update CLI documentation
5. Add example usage to README

## File Organization

```
rqm/
├── rust-core/          # Rust library
│   ├── src/
│   │   ├── lib.rs     # Main library entry
│   │   ├── types.rs   # Core type definitions
│   │   ├── parser.rs  # YAML parsing
│   │   ├── graph.rs   # Graph traversal & cycle detection
│   │   └── validator.rs # Schema validation
│   └── Cargo.toml
├── go-cli/             # Go CLI
│   ├── cmd/           # CLI commands
│   ├── pkg/           # Internal packages
│   └── main.go
├── web-ui/             # React app
│   ├── src/
│   │   ├── components/
│   │   ├── types/
│   │   └── App.tsx
│   └── package.json
└── examples/           # Sample requirement files
```

## Requirement-Driven Development (RDD)

**RQM uses itself to manage its own requirements!**

### RDD Workflow
1. **Define Requirement** in `.rqm/requirements.yml`
2. **Write Acceptance Test** in `tests/acceptance/test_*.sh`
3. **Run Test** (expect failure initially)
4. **Implement Code** to satisfy acceptance criteria
5. **Add Sub-Requirements** as you break down the work
6. **Iterate** until parent requirement's test passes

### Before Implementing Features
- Check `.rqm/requirements.yml` for the requirement
- Verify acceptance test exists
- Understand acceptance criteria (Given/When/Then)
- Run acceptance test to see current status

### During Implementation
- Reference requirement ID in commits (e.g., "RQM-001")
- Update requirement status (draft → proposed → approved → implemented)
- Add sub-requirements for technical details
- Run acceptance tests frequently

### Commit Format for Requirements
```
feat(component): implement REQ-ID requirement name

Satisfies RQM-XXX acceptance criteria:
- ✓ Criterion 1
- ✓ Criterion 2

Acceptance test: tests/acceptance/test_feature.sh
```

## AI Assistant Best Practices

- When generating code, respect the language-specific conventions above
- Always consider circular reference scenarios when working with requirement graphs
- Generate tests alongside implementation code
- Update documentation when changing APIs
- Use semantic versioning principles for breaking changes
- Reference the schema when working with YAML structures
- Consider cross-component impacts (Rust changes may affect Go CLI and Web UI)
- **Follow RDD workflow**: Check requirements before coding, update status after

## Quality Assurance Requirements

### Testing
- **ALWAYS** write unit tests for new code
- Run tests before committing: `cargo test`, `go test ./...`, `npm test`
- Aim for high test coverage on critical paths
- Test edge cases, error conditions, and circular references
- Use table-driven tests in Go for multiple test cases

### Linting and Formatting
- **Rust**: Run `cargo fmt` and `cargo clippy` before every commit
- **Go**: Run `gofmt` and `golangci-lint run` before every commit
- **TypeScript**: Run `npm run lint` and `npm run format` before every commit
- Fix all clippy warnings and linter errors before committing
- Configure pre-commit hooks to enforce formatting

### Commit Standards
- Use **conventional commits** format: `type(scope): description`
  - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
  - Examples: `feat(parser): add YAML parsing support`, `fix(graph): handle circular references`
- Use **commitlint** to enforce commit message standards
- Use **husky** for git hooks to run linting and tests
- Keep commits atomic and focused
- Write descriptive commit messages

### Release Management
- **DO NOT** create git tags or publish releases automatically
- Versions are managed manually by the maintainer
- CI/CD builds and tests but does not publish
- Version bumps require manual PR review

## Dependencies to Prefer

### Rust
- `serde`, `serde_yaml` - YAML handling
- `thiserror` - Error types
- `petgraph` - Graph algorithms
- `jsonschema` - Schema validation

### Go
- `cobra` - CLI framework
- `viper` - Configuration
- `logrus` or `zap` - Logging
- `testify` - Testing assertions

### TypeScript/React
- `react-flow` or `vis-network` - Graph visualization
- `react-query` - Data fetching
- `zod` - Runtime validation
- `tailwindcss` - Styling
