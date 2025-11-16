package cmd

import (
	"os"
	"path/filepath"
	"testing"
)

func TestValidateCommand(t *testing.T) {
	tests := []struct {
		name        string
		setupFile   func() (string, error)
		wantErr     bool
		errContains string
	}{
		{
			name: "valid requirements file",
			setupFile: func() (string, error) {
				tmpfile, err := os.CreateTemp("", "valid-*.yml")
				if err != nil {
					return "", err
				}
				content := `version: "1.0"
requirements:
  - summary: Test Requirement
    name: TEST-001
    owner: test@example.com
    status: draft
    priority: medium
`
				if _, err := tmpfile.Write([]byte(content)); err != nil {
					return "", err
				}
				tmpfile.Close()
				return tmpfile.Name(), nil
			},
			wantErr: false,
		},
		{
			name: "file with duplicate summaries",
			setupFile: func() (string, error) {
				tmpfile, err := os.CreateTemp("", "duplicate-*.yml")
				if err != nil {
					return "", err
				}
				content := `version: "1.0"
requirements:
  - summary: Duplicate
    name: TEST-001
    owner: test@example.com
  - summary: Duplicate
    name: TEST-002
    owner: test@example.com
`
				if _, err := tmpfile.Write([]byte(content)); err != nil {
					return "", err
				}
				tmpfile.Close()
				return tmpfile.Name(), nil
			},
			wantErr:     true,
			errContains: "validation failed",
		},
		{
			name: "nonexistent file",
			setupFile: func() (string, error) {
				return "/nonexistent/path/to/file.yml", nil
			},
			wantErr:     true,
			errContains: "does not exist",
		},
		{
			name: "invalid YAML syntax",
			setupFile: func() (string, error) {
				tmpfile, err := os.CreateTemp("", "invalid-*.yml")
				if err != nil {
					return "", err
				}
				content := `version: "1.0"
requirements:
  - summary: Test
    - invalid: structure
`
				if _, err := tmpfile.Write([]byte(content)); err != nil {
					return "", err
				}
				tmpfile.Close()
				return tmpfile.Name(), nil
			},
			wantErr:     true,
			errContains: "validation failed",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			filepath, err := tt.setupFile()
			if err != nil {
				t.Fatalf("Failed to setup test file: %v", err)
			}

			// Clean up temp file after test
			if filepath != "/nonexistent/path/to/file.yml" {
				defer os.Remove(filepath)
			}

			// Run validation
			err = runValidation(filepath)

			// Check error expectations
			if tt.wantErr && err == nil {
				t.Errorf("Expected error but got none")
			}
			if !tt.wantErr && err != nil {
				t.Errorf("Expected no error but got: %v", err)
			}
			if tt.wantErr && tt.errContains != "" && err != nil {
				if !contains(err.Error(), tt.errContains) {
					t.Errorf("Expected error to contain %q but got: %v", tt.errContains, err)
				}
			}
		})
	}
}

func TestFindValidatorBinary(t *testing.T) {
	binary := findValidatorBinary()
	if binary == "" {
		t.Error("Expected to find validator binary but got empty string")
	}

	// Check if binary exists
	if _, err := os.Stat(binary); os.IsNotExist(err) {
		t.Errorf("Validator binary does not exist at: %s", binary)
	}
}

func TestValidateCommandIntegration(t *testing.T) {
	// Test with actual example file
	exampleFile := filepath.Join("..", "..", "examples", "sample-requirements.yml")
	if _, err := os.Stat(exampleFile); os.IsNotExist(err) {
		t.Skip("Example file not found, skipping integration test")
	}

	err := runValidation(exampleFile)
	if err != nil {
		t.Errorf("Failed to validate example file: %v", err)
	}
}

// Helper function
func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > len(substr) &&
		(s[:len(substr)] == substr || s[len(s)-len(substr):] == substr ||
			findSubstring(s, substr)))
}

func findSubstring(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
