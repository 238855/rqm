# Binary Distribution

This directory contains the Node.js wrapper and prebuilt binaries for distribution.

## Files

- **rqm.js** - Node.js wrapper script that detects platform and executes the appropriate binary
- **dist/** - Prebuilt binaries for all supported platforms

## Prebuilt Binaries

The `dist/` directory contains cross-compiled binaries for:

- **macOS**: Intel (amd64) and Apple Silicon (arm64)
- **Linux**: x86_64 (amd64) and ARM64
- **Windows**: x86_64 (amd64), ARM64, and 32-bit (386)

## Building Binaries

To rebuild all platform binaries:

```bash
npm run build:binaries
# or
./scripts/build-binaries.sh
```

This creates optimized binaries (~5MB each) in `bin/dist/`.

## How It Works

1. User installs package (from npm or GitHub)
2. npm creates symlinks in `node_modules/.bin/` pointing to `bin/rqm.js`
3. When user runs `rqm`, the wrapper:
   - Detects OS (darwin/linux/win32) and architecture (x64/arm64/ia32)
   - Selects appropriate binary from `bin/dist/`
   - Executes binary with all arguments
   - Returns exit code to caller

## Distribution

**For npm publishing:**
- Binaries are committed to the repository
- Package includes `bin/` directory (specified in `package.json` files array)
- Users get plug-and-play installation with no compilation needed

**For GitHub installs:**
- Must commit binaries to repository for them to be available
- `npm install github:238855/rqm` includes all binaries
- Works immediately without requiring Go/Rust toolchains

## Total Size

All 7 binaries: ~36MB total
This is acceptable for a CLI tool and eliminates compilation requirements.
