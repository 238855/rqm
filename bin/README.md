# Binary Distribution

This directory contains the Node.js wrapper and binaries for distribution.

## Build Modes

RQM supports two build modes:

### 1. Unified Binary (Recommended) ⭐

Single self-contained binary with embedded Rust validator via CGO.

**Advantages:**
- ✅ Single ~5MB binary per platform
- ✅ No external dependencies
- ✅ Rust validator embedded (no subprocess calls)
- ✅ Fast validation performance
- ✅ Easy distribution

**Requirements:**
- CGO enabled during build
- Platform-specific Rust library

**Build:**
```bash
./scripts/build-rqm.sh --unified
```

**Result:** `bin/dist/rqm-macos-amd64` (5.2MB), `bin/dist/rqm-macos-arm64` (4.9MB)

### 2. Separate Binaries (Fallback)

Go binary + external Rust validator binary.

**Advantages:**
- ✅ No CGO required (pure Go cross-compilation)
- ✅ Easy to build for all platforms
- ✅ Smaller Go binary (~2MB)

**Disadvantages:**
- ❌ Requires external `rqm-validator` binary
- ❌ Subprocess overhead for validation
- ❌ Two binaries to distribute

**Build:**
```bash
./scripts/build-rqm.sh --separate
```

## Distribution Structure

### Current (Development)

```
bin/
├── rqm.js              # Node.js wrapper (detects platform)
├── dist/
│   ├── rqm-macos-amd64      # 5.2MB unified binary
│   ├── rqm-macos-arm64      # 4.9MB unified binary
│   ├── rqm-linux-amd64      # (future)
│   ├── rqm-linux-arm64      # (future)
│   └── rqm-windows-amd64.exe  # (future)
└── README.md           # This file
```

### For npm Distribution

```
@requiem-org/rqm/
├── bin/
│   ├── rqm.js          # Wrapper detects OS/arch
│   └── dist/
│       ├── rqm-macos-amd64
│       ├── rqm-macos-arm64
│       ├── rqm-linux-amd64
│       ├── rqm-linux-arm64
│       └── rqm-windows-amd64.exe
├── package.json
├── README.md
└── LICENSE
```

**Total size:** ~50MB for all 7 unified binaries (vs ~36MB for separate + need Rust binaries too)

## How It Works

1. User runs `npm install @requiem-org/rqm` or `npm install github:238855/rqm`
2. npm creates symlinks in `node_modules/.bin/`: `rqm` → `../rqm/bin/rqm.js`
3. When user runs `rqm validate file.yml`:
   - `bin/rqm.js` detects OS (darwin/linux/win32) and arch (x64/arm64)
   - Selects appropriate binary from `bin/dist/`
   - Executes with all arguments
   - Returns exit code

4. The binary:
   - **Unified mode:** Validates using embedded Rust library (CGO)
   - **Separate mode:** Spawns external `rqm-validator` binary

## Cross-Platform Builds

### macOS (native)
✅ Fully supported for both Intel and Apple Silicon

### Linux
⚠️ Requires cross-compilation toolchain for unified builds
✅ Easy with separate builds (pure Go)

### Windows  
⚠️ Requires MinGW for unified builds
✅ Easy with separate builds (pure Go)

## Testing

```bash
# Test unified binary
./bin/dist/rqm-macos-amd64 validate examples/sample-requirements.yml

# Should show:
# Validating examples/sample-requirements.yml (using embedded validator)...
# ✓ YAML syntax valid
# ✓ Schema validation passed
```
