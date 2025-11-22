# CI/CD Workflows

This directory contains GitHub Actions workflows for building and releasing RQM.

## Workflows

### 1. `build-dev.yml` - Development Builds

**Trigger:** Every push to `develop` branch

**Purpose:** Build unified binaries for testing

**Artifacts (Private - 30 day retention):**
- `rqm-macos-amd64`
- `rqm-macos-arm64`
- `rqm-linux-amd64`
- `rqm-linux-arm64`
- `rqm-windows-amd64.exe`
- `rqm-dev-all-platforms` (combined archive)

**Access:** Only users with repository access can download artifacts

**Download:**
1. Go to Actions tab
2. Click on latest "Build Dev Binaries" run
3. Scroll to "Artifacts" section
4. Download the binary for your platform

### 2. `release.yml` - Production Releases

**Trigger:** Pushing version tags (e.g., `v0.1.0`)

**Jobs:**
1. **Build binaries** for all platforms (5 platforms)
2. **Create GitHub Release** with binaries attached
3. **Publish to npm** (if stable version)

**Artifacts (Public - 90 day retention):**
- All platform binaries
- SHA256 checksums

**Release Process:**
```bash
# 1. Update version in package.json
npm version patch|minor|major

# 2. Push tag
git push origin v0.1.0

# 3. GitHub Actions will:
#    - Build all binaries
#    - Create GitHub Release
#    - Publish to npm (if stable)
```

### 3. `ci.yml` - Continuous Integration

**Trigger:** Every push, every PR

**Purpose:** Run tests and linting

**Jobs:**
- Rust tests (`cargo test`)
- Go tests (`go test`)
- Rust linting (`cargo clippy`)
- Go linting (`golangci-lint`)
- Prettier formatting check

## Binary Distribution Strategy

### Development (develop branch)
- ✅ Build on every push
- ✅ Store as private GitHub Actions artifacts
- ✅ 30-day retention
- ❌ NOT published to npm
- ❌ NOT in git repository

### Releases (version tags)
- ✅ Build unified binaries with embedded Rust
- ✅ Attach to GitHub Release (public download)
- ✅ Publish to npm registry
- ✅ Include SHA256 checksums
- ❌ NOT committed to git

## Why This Approach?

### ✅ Advantages:
1. **Fast Installation:** Pre-built binaries = instant npm install
2. **No Build Tools Required:** Users don't need Rust/Go
3. **Consistent Builds:** Built in controlled CI environment
4. **Private Dev Builds:** Artifacts only accessible to team
5. **Small Repo:** Binaries not in git (repo stays small)

### 📊 Size Comparison:
- **Unified binary:** ~5MB per platform
- **All 5 platforms:** ~25MB total
- **npm package:** ~30MB (includes wrapper + docs)

### 🔐 Security:
- Dev artifacts require GitHub authentication
- Release binaries have SHA256 checksums
- npm publishes with provenance attestation

## Accessing Dev Builds

### Via GitHub Actions UI:
1. Navigate to: https://github.com/238855/rqm/actions
2. Click on latest "Build Dev Binaries" workflow
3. Scroll to "Artifacts" section
4. Download for your platform

### Via GitHub CLI:
```bash
# List recent artifacts
gh run list --workflow=build-dev.yml

# Download specific artifact
gh run download <run-id> --name rqm-macos-amd64
```

### Via API:
```bash
# Get artifact download URL
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/238855/rqm/actions/artifacts
```

## npm Installation

### From npm Registry (Stable Releases):
```bash
npm install -g @requiem-org/rqm
```

### From GitHub (Latest Code):
```bash
# Installs from latest commit on default branch
npm install -g github:238855/rqm

# Note: This installs source code, not pre-built binaries
# Binaries are built via postinstall script (requires Rust/Go)
```

### From Tarball (Manual):
```bash
# Download release from GitHub
wget https://github.com/238855/rqm/releases/download/v0.1.0/rqm-macos-arm64

# Or use binaries from CI artifacts
chmod +x rqm-macos-arm64
./rqm-macos-arm64 --version
```

## Platform Support

| Platform | Architecture | Unified Binary | Separate Binary |
|----------|--------------|----------------|-----------------|
| macOS    | Intel (x64)  | ✅             | ✅              |
| macOS    | ARM64        | ✅             | ✅              |
| Linux    | x86_64       | ✅             | ✅              |
| Linux    | ARM64        | ✅             | ✅              |
| Windows  | x86_64       | ✅             | ✅              |

## Build Matrix

### Unified Binaries (Recommended)
- **Requires:** CGO + Rust + Go
- **Size:** ~5MB per binary
- **Features:** Embedded Rust validator
- **Cross-compilation:** Complex (platform-specific toolchains)

### Separate Binaries (Fallback)
- **Requires:** Go only (pure Go)
- **Size:** ~2MB + separate Rust binary
- **Features:** External Rust validator process
- **Cross-compilation:** Easy (Go native)

## Troubleshooting

### Artifact Not Found
- Artifacts expire after 30 days (dev) or 90 days (release)
- Check workflow run date
- Re-run workflow if needed

### Binary Won't Execute
```bash
# macOS: Remove quarantine
xattr -d com.apple.quarantine rqm-macos-amd64

# Linux: Make executable
chmod +x rqm-linux-amd64
```

### NPM_TOKEN Not Set
1. Create token: `npm token create`
2. Add to GitHub: Settings → Secrets → Actions → New secret
3. Name: `NPM_TOKEN`
4. Value: Your token

## Future Improvements

- [ ] Code signing for macOS/Windows binaries
- [ ] Notarization for macOS binaries
- [ ] Multi-arch Docker images
- [ ] ARM64 Windows support
- [ ] FreeBSD/OpenBSD support
