# RQM - Requirements Management in Code

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](https://github.com/238855/rqm/releases)

**RQM** (also usable as `requim`) is a powerful requirements management tool that allows you to manage requirements as code using structured YAML files.

> **Note:** This project was bootstrapped with assistance from [Claude Code](https://claude.ai/code) by Anthropic.

## 🎯 Overview

RQM enables teams to:
- **Define requirements as code** using YAML files with full validation
- **Build requirement trees** with support for complex relationships including circular references
- **Track ownership and accountability** with flexible person references
- **Link to acceptance tests** and additional documentation
- **Visualize requirements** through an interactive web UI
- **Query and validate** requirements via a powerful CLI

## 🏗️ Architecture

This is a polyglot monorepo containing:

- **`rust-core/`** - Core library written in Rust for parsing, validation, and graph traversal
- **`go-cli/`** - Command-line interface written in Go (provides `rqm` and `requim` commands)
- **`web-ui/`** - React TypeScript web application for visualizing requirement trees
- **`examples/`** - Sample requirement files demonstrating the system
- **`docs/`** - Comprehensive documentation

## 📋 Requirement Structure

Each requirement can have:

- **summary** (required, unique) - Short text identifier
- **name** (optional) - Human-friendly name
- **description** - Long text describing the requirement
- **justification** - Rationale for the requirement
- **acceptance_test** - Test criteria text
- **acceptance_test_link** - URL to test documentation
- **owner** - Person reference (email, GitHub username, or alias)
- **requirements** - Array of nested requirements or references
- **further_information** - Array of text items or URLs

### Circular Reference Handling

The system intelligently handles circular references to prevent infinite loops during traversal, using:
- Visited node tracking during graph traversal
- Depth limiting for nested expansions
- Reference counting and cycle detection

## 🚀 Quick Start

### Prerequisites

- Rust 1.70+ (for core library)
- Go 1.21+ (for CLI)
- Node.js 18+ (for web UI)

### Installation

```bash
# Clone the repository
git clone https://github.com/238855/rqm.git
cd rqm

# Build the Rust core
cd rust-core
cargo build --release

# Build the Go CLI
cd ../go-cli
go build -o rqm

# Install the web UI dependencies
cd ../web-ui
npm install
```

### Usage

```bash
# Validate requirements
rqm validate requirements.yml

# List all requirements
rqm list

# Query specific requirement
rqm get <requirement-id>

# Start web UI
cd web-ui && npm run dev
```

## 📝 Example Requirement File

```yaml
version: "1.0"
aliases:
  - alias: john
    email: john@example.com
    github: johndoe

requirements:
  - summary: User Authentication
    name: AUTH-001
    description: |
      The system must provide secure user authentication
      using industry-standard protocols.
    justification: Security is paramount for user data protection
    acceptance_test: User can log in with valid credentials
    acceptance_test_link: https://example.com/tests/auth
    owner: john
    requirements:
      - summary: Password Hashing
        description: Passwords must be hashed using bcrypt
        owner: john
```

## 🔄 Versioning

This project uses [Semantic Versioning](https://semver.org/). Current version: **0.1.0**

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with assistance from Claude Code (Anthropic)
- Inspired by the need for better requirements traceability in software development

## 🗺️ Roadmap

- [ ] v0.1.0 - Initial release with core functionality
- [ ] v0.2.0 - Advanced graph visualization
- [ ] v0.3.0 - Integration with issue trackers
- [ ] v1.0.0 - Production-ready release

---

**Maintainer:** [238855](https://github.com/238855)
