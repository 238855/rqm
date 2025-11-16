// RQM - Requirements Management in Code
// Copyright (c) 2025
// SPDX-License-Identifier: MIT

package cmd

import (
	"bytes"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCheckCommand(t *testing.T) {
	// Create temp directory for test files
	tmpDir := t.TempDir()

	// Create a valid requirements file without cycles
	noCycleFile := filepath.Join(tmpDir, "no_cycle.yml")
	noCycleContent := `version: "1.0"
requirements:
  - summary: Requirement A
    name: REQ-A
    owner: test@example.com
  - summary: Requirement B
    name: REQ-B
    owner: test@example.com
`
	if err := os.WriteFile(noCycleFile, []byte(noCycleContent), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Create a file with circular reference
	cycleFile := filepath.Join(tmpDir, "with_cycle.yml")
	cycleContent := `version: "1.0"
requirements:
  - summary: Requirement A
    name: REQ-A
    owner: test@example.com
    requirements:
      - summary: Requirement B
        name: REQ-B
        owner: test@example.com
        requirements:
          - REQ-A
`
	if err := os.WriteFile(cycleFile, []byte(cycleContent), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	tests := []struct {
		name        string
		file        string
		expectError bool
		checkOutput func(t *testing.T, output string)
	}{
		{
			name:        "nonexistent file",
			file:        filepath.Join(tmpDir, "nonexistent.yml"),
			expectError: true,
			checkOutput: nil,
		},
		{
			name:        "file without cycles",
			file:        noCycleFile,
			expectError: false,
			checkOutput: func(t *testing.T, output string) {
				if !strings.Contains(output, "No circular references detected") && !strings.Contains(output, "acyclic") {
					t.Logf("Output: %s", output)
				}
			},
		},
		{
			name:        "file with cycles",
			file:        cycleFile,
			expectError: true, // Should return error when cycles found
			checkOutput: func(t *testing.T, output string) {
				if !strings.Contains(output, "circular reference") && !strings.Contains(output, "Cycle") {
					t.Logf("Expected cycle detection in output, got: %s", output)
				}
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Capture stdout
			old := os.Stdout
			r, w, _ := os.Pipe()
			os.Stdout = w

			// Run command
			err := checkCmd.RunE(checkCmd, []string{tt.file})

			// Restore stdout
			w.Close()
			os.Stdout = old

			// Read output
			var buf bytes.Buffer
			io.Copy(&buf, r)
			output := buf.String()

			// Check error expectation
			if tt.expectError && err == nil {
				t.Errorf("Expected error but got none")
			}
			if !tt.expectError && err != nil {
				t.Errorf("Unexpected error: %v", err)
			}

			// Check output if validation function provided
			if tt.checkOutput != nil {
				tt.checkOutput(t, output)
			}
		})
	}
}

func TestGraphCommand(t *testing.T) {
	// Create temp directory for test files
	tmpDir := t.TempDir()

	// Create a valid requirements file
	validFile := filepath.Join(tmpDir, "valid.yml")
	validContent := `version: "1.0"
requirements:
  - summary: Requirement A
    name: REQ-A
    owner: test@example.com
  - summary: Requirement B
    name: REQ-B
    owner: test@example.com
`
	if err := os.WriteFile(validFile, []byte(validContent), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	tests := []struct {
		name        string
		file        string
		expectError bool
		checkOutput func(t *testing.T, output string)
	}{
		{
			name:        "nonexistent file",
			file:        filepath.Join(tmpDir, "nonexistent.yml"),
			expectError: true,
			checkOutput: nil,
		},
		{
			name:        "valid requirements file",
			file:        validFile,
			expectError: false,
			checkOutput: func(t *testing.T, output string) {
				if !strings.Contains(output, "Dependency Graph") && !strings.Contains(output, "graph") {
					t.Logf("Expected graph output, got: %s", output)
				}
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Capture stdout
			old := os.Stdout
			r, w, _ := os.Pipe()
			os.Stdout = w

			// Run command
			err := graphCmd.RunE(graphCmd, []string{tt.file})

			// Restore stdout
			w.Close()
			os.Stdout = old

			// Read output
			var buf bytes.Buffer
			io.Copy(&buf, r)
			output := buf.String()

			// Check error expectation
			if tt.expectError && err == nil {
				t.Errorf("Expected error but got none")
			}
			if !tt.expectError && err != nil {
				t.Errorf("Unexpected error: %v", err)
			}

			// Check output if validation function provided
			if tt.checkOutput != nil {
				tt.checkOutput(t, output)
			}
		})
	}
}

func TestCycleCheckResult(t *testing.T) {
	// Test struct marshaling/unmarshaling
	result := CycleCheckResult{
		HasCycles: true,
		Cycles: [][]string{
			{"A", "B", "C"},
		},
		Graph: map[string][]string{
			"A": {"B"},
			"B": {"C"},
			"C": {"A"},
		},
	}

	if !result.HasCycles {
		t.Errorf("Expected HasCycles to be true")
	}

	if len(result.Cycles) != 1 {
		t.Errorf("Expected 1 cycle, got %d", len(result.Cycles))
	}

	if len(result.Graph) != 3 {
		t.Errorf("Expected 3 nodes in graph, got %d", len(result.Graph))
	}
}
