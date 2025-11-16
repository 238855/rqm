// RQM - Requirements Management in Code
// Copyright (c) 2025
// SPDX-License-Identifier: MIT

package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/spf13/cobra"
)

type ValidationResult struct {
	Valid    bool     `json:"valid"`
	Errors   []string `json:"errors"`
	Warnings []string `json:"warnings"`
}

var validateCmd = &cobra.Command{
	Use:   "validate [file]",
	Short: "Validate a requirements YAML file",
	Long: `Validate a requirements YAML file against the JSON schema.
    
This command checks:
  - YAML syntax is valid
  - File conforms to the requirements schema
  - All summaries are unique
  - Owner references are valid
  - Circular references are detected`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		file := args[0]
		return runValidation(file)
	},
}

// runValidation performs the validation logic
func runValidation(file string) error {
	// Check if file exists
	if _, err := os.Stat(file); os.IsNotExist(err) {
		return fmt.Errorf("file does not exist: %s", file)
	}

	// Find the rqm-validator binary
	validatorPath := findValidatorBinary()
	if validatorPath == "" {
		return fmt.Errorf("rqm-validator binary not found\nPlease run: cd rust-core && cargo build --release --bin rqm-validator")
	}

	// Call rust-core validator
	fmt.Printf("Validating %s...\n", file)

	validatorCmd := exec.Command(validatorPath, file)
	output, _ := validatorCmd.CombinedOutput()

	// Parse JSON output
	var result ValidationResult
	if jsonErr := json.Unmarshal(output, &result); jsonErr != nil {
		return fmt.Errorf("failed to parse validator output: %w\nOutput: %s", jsonErr, string(output))
	}

	// Display results
	if result.Valid {
		fmt.Println("✓ YAML syntax valid")
		fmt.Println("✓ Schema validation passed")
		fmt.Println("✓ All summaries unique")
		fmt.Println("✓ Owner references valid")
		fmt.Println("\nValidation successful!")
		return nil
	}

	// Display errors
	fmt.Println("\n✗ Validation failed:")
	for _, errMsg := range result.Errors {
		fmt.Printf("  - %s\n", errMsg)
	}

	// Display warnings if any
	if len(result.Warnings) > 0 {
		fmt.Println("\nWarnings:")
		for _, warning := range result.Warnings {
			fmt.Printf("  ⚠ %s\n", warning)
		}
	}

	return fmt.Errorf("validation failed with %d error(s)", len(result.Errors))
}

// findValidatorBinary locates the rqm-validator binary
func findValidatorBinary() string {
	// Get current working directory to help construct relative paths
	cwd, _ := os.Getwd()

	// Try relative paths from various locations
	paths := []string{
		"../rust-core/target/release/rqm-validator",
		"../rust-core/target/debug/rqm-validator",
		"rust-core/target/release/rqm-validator",
		"rust-core/target/debug/rqm-validator",
		"../../rust-core/target/release/rqm-validator",
		"../../rust-core/target/debug/rqm-validator",
	}

	// If running from go-cli, also try relative to parent
	if filepath.Base(cwd) == "go-cli" || filepath.Base(filepath.Dir(cwd)) == "go-cli" {
		parentDir := filepath.Dir(cwd)
		if filepath.Base(cwd) == "cmd" {
			parentDir = filepath.Dir(parentDir)
		}
		paths = append(paths,
			filepath.Join(parentDir, "rust-core/target/release/rqm-validator"),
			filepath.Join(parentDir, "rust-core/target/debug/rqm-validator"),
		)
	}

	for _, path := range paths {
		absPath, err := filepath.Abs(path)
		if err != nil {
			continue
		}
		if _, err := os.Stat(absPath); err == nil {
			return absPath
		}
	}

	return ""
}

func init() {
	rootCmd.AddCommand(validateCmd)
}
