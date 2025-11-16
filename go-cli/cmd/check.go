// RQM - Requirements Management in Code
// Copyright (c) 2025
// SPDX-License-Identifier: MIT

package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/spf13/cobra"
)

type CycleCheckResult struct {
	HasCycles bool                `json:"has_cycles"`
	Cycles    [][]string          `json:"cycles"`
	Graph     map[string][]string `json:"graph"`
}

var checkCmd = &cobra.Command{
	Use:   "check [file]",
	Short: "Check for circular references in requirements",
	Long: `Check for circular references (cycles) in the requirements graph.
	
Circular references occur when requirements form dependency loops:
  - A → B → A (simple cycle)
  - A → B → C → A (complex cycle)
  - A → A (self-reference)

This command uses graph traversal algorithms to detect all cycles.`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		file := args[0]

		// Check if file exists
		if _, err := os.Stat(file); os.IsNotExist(err) {
			return fmt.Errorf("file does not exist: %s", file)
		}

		// Find the rqm-validator binary
		validatorPath := findValidatorBinary()
		if validatorPath == "" {
			return fmt.Errorf("rqm-validator binary not found")
		}

		// Call rust-core validator with --check-cycles flag
		validatorCmd := exec.Command(validatorPath, file, "--check-cycles")
		output, _ := validatorCmd.CombinedOutput()

		// Parse the result
		var result CycleCheckResult
		if jsonErr := json.Unmarshal(output, &result); jsonErr != nil {
			return fmt.Errorf("failed to parse cycle check result: %w\nOutput: %s", jsonErr, string(output))
		}

		// Display results
		fmt.Printf("Checking %s for circular references...\n\n", file)

		if !result.HasCycles {
			fmt.Println("✓ No circular references detected")
			fmt.Println("  The requirements graph is acyclic (DAG)")
			return nil
		}

		// Display cycles found
		fmt.Printf("✗ Found %d circular reference(s):\n\n", len(result.Cycles))
		for i, cycle := range result.Cycles {
			fmt.Printf("Cycle %d:\n", i+1)
			for j, node := range cycle {
				if j == len(cycle)-1 {
					fmt.Printf("  └─ %s → (back to %s)\n", node, cycle[0])
				} else {
					fmt.Printf("  ├─ %s\n", node)
					if j < len(cycle)-2 {
						fmt.Printf("  │  ↓\n")
					}
				}
			}
			fmt.Println()
		}

		fmt.Println("⚠ Circular references can cause infinite loops during traversal.")
		fmt.Println("  Consider restructuring your requirements to remove cycles.")

		return fmt.Errorf("circular references detected")
	},
}

var graphCmd = &cobra.Command{
	Use:   "graph [file]",
	Short: "Display the requirements dependency graph",
	Long: `Display the requirements dependency graph in various formats.
	
Shows the relationship between requirements and their dependencies.
Useful for understanding the structure and detecting patterns.`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		file := args[0]

		// Check if file exists
		if _, err := os.Stat(file); os.IsNotExist(err) {
			return fmt.Errorf("file does not exist: %s", file)
		}

		// Find the rqm-validator binary
		validatorPath := findValidatorBinary()
		if validatorPath == "" {
			return fmt.Errorf("rqm-validator binary not found")
		}

		// Call rust-core validator with --graph flag
		validatorCmd := exec.Command(validatorPath, file, "--graph")
		output, _ := validatorCmd.CombinedOutput()
		if validatorPath == "" {
			return fmt.Errorf("failed to generate graph: %s", string(output))
		}

		// Parse the result
		var result CycleCheckResult
		if jsonErr := json.Unmarshal(output, &result); jsonErr != nil {
			return fmt.Errorf("failed to parse graph result: %w\nOutput: %s", jsonErr, string(output))
		}

		// Display graph
		fmt.Printf("Requirements Dependency Graph for %s:\n\n", file)

		if len(result.Graph) == 0 {
			fmt.Println("  (empty graph)")
			return nil
		}

		// Display each node and its dependencies
		for node, deps := range result.Graph {
			if len(deps) == 0 {
				fmt.Printf("  %s → (no dependencies)\n", node)
			} else {
				fmt.Printf("  %s → %s\n", node, strings.Join(deps, ", "))
			}
		}

		fmt.Println()
		if result.HasCycles {
			fmt.Printf("⚠ Warning: Graph contains %d cycle(s)\n", len(result.Cycles))
		} else {
			fmt.Println("✓ Graph is acyclic (DAG)")
		}

		return nil
	},
}

func init() {
	rootCmd.AddCommand(checkCmd)
	rootCmd.AddCommand(graphCmd)
}
