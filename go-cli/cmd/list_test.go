// RQM - Requirements Management in Code
// Copyright (c) 2025
// SPDX-License-Identifier: MIT

package cmd

import (
	"bytes"
	"encoding/json"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestListCommand(t *testing.T) {
	// Create temp directory for test files
	tmpDir := t.TempDir()

	// Create a valid requirements file
	validFile := filepath.Join(tmpDir, "valid.yml")
	validContent := `version: "1.0"
requirements:
  - summary: Test Requirement
    name: TEST-001
    description: A test requirement
    owner: test@example.com
    priority: high
    status: implemented
    tags:
      - test
    requirements:
      - summary: Child Requirement
        name: TEST-001.1
        owner: test@example.com
        status: draft
`
	if err := os.WriteFile(validFile, []byte(validContent), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	tests := []struct {
		name        string
		file        string
		format      string
		details     bool
		expectError bool
		checkOutput func(t *testing.T, output string)
	}{
		{
			name:        "nonexistent file",
			file:        filepath.Join(tmpDir, "nonexistent.yml"),
			format:      "tree",
			expectError: true,
			checkOutput: func(t *testing.T, output string) {
				// Error message is in the error, not stdout
			},
		},
		{
			name:        "tree format without details",
			file:        validFile,
			format:      "tree",
			details:     false,
			expectError: false,
			checkOutput: func(t *testing.T, output string) {
				if !strings.Contains(output, "Test Requirement") {
					t.Errorf("Expected 'Test Requirement' in output, got: %s", output)
				}
				if !strings.Contains(output, "TEST-001") {
					t.Errorf("Expected 'TEST-001' in output, got: %s", output)
				}
			},
		},
		{
			name:        "tree format with details",
			file:        validFile,
			format:      "tree",
			details:     true,
			expectError: false,
			checkOutput: func(t *testing.T, output string) {
				if !strings.Contains(output, "Owner:") {
					t.Errorf("Expected 'Owner:' in detailed output, got: %s", output)
				}
				if !strings.Contains(output, "test@example.com") {
					t.Errorf("Expected owner email in output, got: %s", output)
				}
			},
		},
		{
			name:        "table format",
			file:        validFile,
			format:      "table",
			expectError: false,
			checkOutput: func(t *testing.T, output string) {
				if !strings.Contains(output, "ID") || !strings.Contains(output, "Summary") {
					t.Errorf("Expected table headers in output, got: %s", output)
				}
				if !strings.Contains(output, "TEST-001") {
					t.Errorf("Expected TEST-001 in table, got: %s", output)
				}
			},
		},
		{
			name:        "json format",
			file:        validFile,
			format:      "json",
			expectError: false,
			checkOutput: func(t *testing.T, output string) {
				var config RequirementConfig
				if err := json.Unmarshal([]byte(output), &config); err != nil {
					t.Errorf("Expected valid JSON output, got error: %v", err)
				}
				if len(config.Requirements) == 0 {
					t.Errorf("Expected requirements in JSON output")
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

			// Set flags
			outputFormat = tt.format
			showDetails = tt.details

			// Run command directly via RunE function
			err := listCmd.RunE(listCmd, []string{tt.file})

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

			// Check error message if error expected
			if tt.expectError && err != nil {
				if !strings.Contains(err.Error(), "does not exist") && !strings.Contains(err.Error(), "not found") {
					t.Logf("Error message: %v", err)
				}
			}

			// Check output if validation function provided
			if tt.checkOutput != nil {
				tt.checkOutput(t, output)
			}
		})
	}
}

func TestGetStatusSymbol(t *testing.T) {
	tests := []struct {
		status   string
		expected string
	}{
		{"implemented", "✓"},
		{"approved", "○"},
		{"proposed", "◐"},
		{"draft", "◯"},
		{"unknown", "·"},
		{"", "·"},
	}

	for _, tt := range tests {
		t.Run(tt.status, func(t *testing.T) {
			result := getStatusSymbol(tt.status)
			if result != tt.expected {
				t.Errorf("getStatusSymbol(%s) = %s, expected %s", tt.status, result, tt.expected)
			}
		})
	}
}

func TestGetPriorityIndicator(t *testing.T) {
	tests := []struct {
		priority string
		expected string
	}{
		{"critical", "🔴"},
		{"high", "🟠"},
		{"medium", "🟡"},
		{"low", "🟢"},
		{"unknown", ""},
		{"", ""},
	}

	for _, tt := range tests {
		t.Run(tt.priority, func(t *testing.T) {
			result := getPriorityIndicator(tt.priority)
			if result != tt.expected {
				t.Errorf("getPriorityIndicator(%s) = %s, expected %s", tt.priority, result, tt.expected)
			}
		})
	}
}

func TestRequirementReference_UnmarshalJSON(t *testing.T) {
	tests := []struct {
		name        string
		json        string
		expectRef   bool
		expectFull  bool
		expectError bool
	}{
		{
			name:      "string reference",
			json:      `"Simple Reference"`,
			expectRef: true,
		},
		{
			name: "full requirement",
			json: `{
				"summary": "Full Requirement",
				"name": "REQ-001",
				"owner": "test@example.com"
			}`,
			expectFull: true,
		},
		{
			name:        "invalid json",
			json:        `{invalid}`,
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var ref RequirementReference
			err := json.Unmarshal([]byte(tt.json), &ref)

			if tt.expectError {
				if err == nil {
					t.Errorf("Expected error but got none")
				}
				return
			}

			if err != nil {
				t.Errorf("Unexpected error: %v", err)
				return
			}

			if tt.expectRef && ref.Reference == "" {
				t.Errorf("Expected reference string but got empty")
			}

			if tt.expectFull && ref.Full == nil {
				t.Errorf("Expected full requirement but got nil")
			}
		})
	}
}

func TestDisplayTree(t *testing.T) {
	config := &RequirementConfig{
		Version: "1.0",
		Requirements: []RequirementDetail{
			{
				Summary: "Parent Requirement",
				Name:    "PARENT-001",
				Owner:   "test@example.com",
				Status:  "implemented",
			},
		},
	}

	// Capture stdout
	old := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w

	displayTree(config, false)

	w.Close()
	os.Stdout = old

	var buf bytes.Buffer
	io.Copy(&buf, r)
	output := buf.String()

	if !strings.Contains(output, "Parent Requirement") {
		t.Errorf("Expected 'Parent Requirement' in output, got: %s", output)
	}
	if !strings.Contains(output, "PARENT-001") {
		t.Errorf("Expected 'PARENT-001' in output, got: %s", output)
	}
	if !strings.Contains(output, "v1.0") {
		t.Errorf("Expected version in output, got: %s", output)
	}
}

func TestDisplayTreeWithAliases(t *testing.T) {
	config := &RequirementConfig{
		Version: "1.0",
		Aliases: []PersonAlias{
			{
				Alias: "dev",
				Name:  "Developer",
				Email: "dev@example.com",
			},
		},
		Requirements: []RequirementDetail{},
	}

	// Capture stdout
	old := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w

	displayTree(config, false)

	w.Close()
	os.Stdout = old

	var buf bytes.Buffer
	io.Copy(&buf, r)
	output := buf.String()

	if !strings.Contains(output, "Aliases:") {
		t.Errorf("Expected 'Aliases:' in output, got: %s", output)
	}
	if !strings.Contains(output, "@dev") {
		t.Errorf("Expected '@dev' in output, got: %s", output)
	}
	if !strings.Contains(output, "Developer") {
		t.Errorf("Expected 'Developer' in output, got: %s", output)
	}
}

func TestDisplayRequirement(t *testing.T) {
	req := &RequirementDetail{
		Summary:     "Test Requirement",
		Name:        "TEST-001",
		Description: "This is a test requirement with a description",
		Owner:       "test@example.com",
		Status:      "implemented",
		Priority:    "high",
		Tags:        []string{"test", "unit"},
	}

	// Capture stdout
	old := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w

	displayRequirement(req, "", true)

	w.Close()
	os.Stdout = old

	var buf bytes.Buffer
	io.Copy(&buf, r)
	output := buf.String()

	if !strings.Contains(output, "Test Requirement") {
		t.Errorf("Expected summary in output, got: %s", output)
	}
	if !strings.Contains(output, "TEST-001") {
		t.Errorf("Expected name in output, got: %s", output)
	}
	if !strings.Contains(output, "Owner:") {
		t.Errorf("Expected owner label in detailed output, got: %s", output)
	}
	if !strings.Contains(output, "Tags:") {
		t.Errorf("Expected tags in detailed output, got: %s", output)
	}
}

func TestDisplayRequirementWithoutDetails(t *testing.T) {
	req := &RequirementDetail{
		Summary:     "Test Requirement",
		Name:        "TEST-001",
		Description: "This is a test requirement",
		Owner:       "test@example.com",
	}

	// Capture stdout
	old := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w

	displayRequirement(req, "", false)

	w.Close()
	os.Stdout = old

	var buf bytes.Buffer
	io.Copy(&buf, r)
	output := buf.String()

	if strings.Contains(output, "Owner:") {
		t.Errorf("Should not show owner in non-detailed output, got: %s", output)
	}
	if strings.Contains(output, "Description:") {
		t.Errorf("Should not show description in non-detailed output, got: %s", output)
	}
}

func TestDisplayTable(t *testing.T) {
	config := &RequirementConfig{
		Requirements: []RequirementDetail{
			{
				Summary:  "Test Requirement",
				Name:     "TEST-001",
				Owner:    "test@example.com",
				Status:   "implemented",
				Priority: "high",
			},
		},
	}

	// Capture stdout
	old := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w

	displayTable(config)

	w.Close()
	os.Stdout = old

	var buf bytes.Buffer
	io.Copy(&buf, r)
	output := buf.String()

	// Check for table headers
	if !strings.Contains(output, "ID") {
		t.Errorf("Expected 'ID' header in table output, got: %s", output)
	}
	if !strings.Contains(output, "Summary") {
		t.Errorf("Expected 'Summary' header in table output, got: %s", output)
	}

	// Check for data
	if !strings.Contains(output, "TEST-001") {
		t.Errorf("Expected 'TEST-001' in table output, got: %s", output)
	}
}

func TestDisplayRequirementRow(t *testing.T) {
	req := &RequirementDetail{
		Summary:  "Test Requirement with a very long summary that should be truncated to fit in the table column width",
		Name:     "TEST-001",
		Owner:    "test@example.com",
		Status:   "implemented",
		Priority: "high",
	}

	// Capture stdout
	old := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w

	displayRequirementRow(req)

	w.Close()
	os.Stdout = old

	var buf bytes.Buffer
	io.Copy(&buf, r)
	output := buf.String()

	if !strings.Contains(output, "TEST-001") {
		t.Errorf("Expected 'TEST-001' in row output, got: %s", output)
	}

	// Check that long summary is truncated
	if strings.Contains(output, "column width") {
		t.Errorf("Long summary should be truncated, got: %s", output)
	}
	if !strings.Contains(output, "...") {
		t.Errorf("Truncated summary should contain '...', got: %s", output)
	}
}

func TestDisplayRequirementRowWithMissingFields(t *testing.T) {
	req := &RequirementDetail{
		Summary: "Minimal Requirement",
		// All other fields empty
	}

	// Capture stdout
	old := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w

	displayRequirementRow(req)

	w.Close()
	os.Stdout = old

	var buf bytes.Buffer
	io.Copy(&buf, r)
	output := buf.String()

	// Should use "-" for missing fields
	if !strings.Contains(output, "-") {
		t.Errorf("Expected '-' for missing fields, got: %s", output)
	}
}
