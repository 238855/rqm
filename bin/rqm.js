#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

// Detect platform and architecture
function getPlatformBinary() {
  const platform = os.platform();
  const arch = os.arch();
  
  const platformMap = {
    'darwin': {
      'x64': 'rqm-macos-amd64',
      'arm64': 'rqm-macos-arm64'
    },
    'linux': {
      'x64': 'rqm-linux-amd64',
      'arm64': 'rqm-linux-arm64'
    },
    'win32': {
      'x64': 'rqm-windows-amd64.exe',
      'arm64': 'rqm-windows-arm64.exe',
      'ia32': 'rqm-windows-386.exe'
    }
  };
  
  if (!platformMap[platform]) {
    return null;
  }
  
  return platformMap[platform][arch] || null;
}

// Try to find the appropriate binary
const binaryName = getPlatformBinary();
let binaryPath = null;

if (binaryName) {
  // Try prebuilt binary first
  binaryPath = path.join(__dirname, '..', 'bin', 'dist', binaryName);
  
  if (!fs.existsSync(binaryPath)) {
    // Fall back to development binary
    const devBinary = path.join(__dirname, '..', 'go-cli', 'rqm');
    if (fs.existsSync(devBinary)) {
      binaryPath = devBinary;
    }
  }
}

// Check if binary exists
if (!binaryPath || !fs.existsSync(binaryPath)) {
  console.error('Error: rqm binary not found for your platform.');
  console.error('');
  console.error(`Platform: ${os.platform()}`);
  console.error(`Architecture: ${os.arch()}`);
  console.error('');
  console.error('You can try building from source:');
  console.error('  cd go-cli && go build -o rqm');
  console.error('');
  console.error('Or download a pre-built binary from:');
  console.error('  https://github.com/238855/rqm/releases');
  process.exit(1);
}

// Execute the binary with all arguments
const child = spawn(binaryPath, process.argv.slice(2), {
  stdio: 'inherit',
  env: process.env
});

child.on('exit', (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
  } else {
    process.exit(code);
  }
});

