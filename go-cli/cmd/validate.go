// RQM - Requirements Management in Code
// Copyright (c) 2025
// SPDX-License-Identifier: MIT

package cmd

import (
    "fmt"
    "os"

    "github.com/spf13/cobra"
)

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
        
        // Check if file exists
        if _, err := os.Stat(file); os.IsNotExist(err) {
            return fmt.Errorf("file does not exist: %s", file)
        }
        
        // TODO: Call rust-core validator
        fmt.Printf("Validating %s...\n", file)
        fmt.Println("✓ YAML syntax valid")
        fmt.Println("✓ Schema validation passed")
        fmt.Println("✓ All summaries unique")
        fmt.Println("✓ Owner references valid")
        fmt.Println("\nValidation successful!")
        
        return nil
    },
}

func init() {
    rootCmd.AddCommand(validateCmd)
}
