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

### For End Users

Install from npm (once published):

```bash
npm install -g @requiem-org/rqm
rqm --version
```

Or install directly from GitHub:

```bash
npm install -g github:238855/rqm
```

### For Developers

#### Prerequisites

- Rust 1.70+ (for core library)
- Go 1.21+ with CGO enabled (for unified binary)
- Node.js 18+ (for web UI)
- GitHub CLI (`gh`) - for dev builds from CI artifacts

#### Development Installation

```bash
# Clone the repository
git clone https://github.com/238855/rqm.git
cd rqm

# Install dependencies
npm install
```

#### Building from Source

**Option 1: Unified Binary (Recommended)**

Build a single self-contained executable with embedded Rust validator:

```bash
# Build for your current platform
./scripts/build-rqm.sh --unified

# Binary will be in go-cli/rqm
./go-cli/rqm --version
```

**Option 2: Separate Binaries**

Build Go CLI and Rust validator as separate executables:

```bash
# Build both components
./scripts/build-rqm.sh --separate

# Go CLI will be in go-cli/rqm
# Rust validator will be in rust-core/target/release/rqm-validator
```

#### Installing Development Builds

To install the latest development build from GitHub Actions artifacts:

```bash
# Install GitHub CLI if needed
brew install gh  # macOS
# or see https://github.com/cli/cli#installation

# Authenticate with GitHub
gh auth login

# Download and install latest dev build
./scripts/install-dev-build.sh
```

This will:
1. Download the latest successful build from the `develop` branch
2. Install all platform binaries to `bin/dist/`
3. Make them available for local testing

**Manual Installation from Artifacts:**

1. Go to [GitHub Actions](https://github.com/238855/rqm/actions/workflows/build-dev.yml)
2. Click the latest successful workflow run
3. Download `rqm-binaries-develop` artifact
4. Extract and use the binary for your platform

**Note:** Development artifacts are private and require authentication. They expire after 30 days.

### Usage

```bash
# Validate requirements
rqm validate requirements.yml

# List all requirements
rqm list requirements.yml

# Check for circular references
rqm check requirements.yml

# Start web UI (coming soon)
rqm serve
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

### Development Workflow

#### CI/CD Overview

The project uses GitHub Actions for automated builds:

- **`build-dev.yml`** - Builds unified binaries on every push to `develop`
  - Creates private artifacts (30-day retention)
  - Accessible only to authenticated repository members
  - Useful for testing before releases

- **`release.yml`** - Builds and publishes on version tags
  - Creates public GitHub Releases
  - Publishes to npm (@requiem-org/rqm)
  - Generates checksums for all binaries

- **`ci.yml`** - Runs tests and linting on all PRs

#### Creating a Release

```bash
# Ensure all tests pass
npm test

# Update version in package.json, Cargo.toml, and go.mod
# Update CHANGELOG.md

# Commit changes
git add -A
git commit -m "chore(release): prepare v0.2.0"
git push

# Create and push tag
git tag v0.2.0
git push origin v0.2.0

# GitHub Actions will automatically:
# 1. Build binaries for all platforms
# 2. Create GitHub Release with binaries
# 3. Publish to npm (for stable versions)
```

#### Binary Distribution

Pre-built binaries are the standard distribution method:
- **Development:** Private GitHub Actions artifacts
- **Production:** Public GitHub Releases + npm registry
- **Platforms:** macOS (ARM64/x64), Linux (ARM64/x64), Windows (x64)
- **Size:** ~5MB per unified binary

For more details, see [`.github/workflows/README.md`](.github/workflows/README.md).

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
