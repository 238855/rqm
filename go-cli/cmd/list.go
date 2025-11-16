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

var (
	outputFormat string
	showDetails  bool
)

var listCmd = &cobra.Command{
	Use:   "list [file]",
	Short: "List all requirements from a YAML file",
	Long: `List all requirements from a YAML file in various formats.
	
Displays requirements in a tree structure by default, showing:
  - Summary
  - Name/ID
  - Owner
  - Status
  - Priority`,
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

		// Call rust-core validator with --format json-full flag
		validatorCmd := exec.Command(validatorPath, file, "--format", "json-full")
		output, _ := validatorCmd.CombinedOutput()
		if validatorPath == "" {
			return fmt.Errorf("failed to parse requirements: %s", string(output))
		}

		// Parse the requirements
		var config RequirementConfig
		if jsonErr := json.Unmarshal(output, &config); jsonErr != nil {
			return fmt.Errorf("failed to parse requirements JSON: %w", jsonErr)
		}

		// Display based on format
		switch outputFormat {
		case "json":
			fmt.Println(string(output))
		case "tree":
			displayTree(&config, showDetails)
		case "table":
			displayTable(&config)
		default:
			return fmt.Errorf("unknown output format: %s", outputFormat)
		}

		return nil
	},
}

type RequirementConfig struct {
	Version      string              `json:"version"`
	Aliases      []PersonAlias       `json:"aliases,omitempty"`
	Requirements []RequirementDetail `json:"requirements"`
}

type PersonAlias struct {
	Alias  string `json:"alias"`
	Name   string `json:"name"`
	Email  string `json:"email"`
	GitHub string `json:"github,omitempty"`
}

type RequirementDetail struct {
	Summary            string                 `json:"summary"`
	Name               string                 `json:"name,omitempty"`
	Description        string                 `json:"description,omitempty"`
	Justification      string                 `json:"justification,omitempty"`
	AcceptanceTest     string                 `json:"acceptance_test,omitempty"`
	AcceptanceTestLink string                 `json:"acceptance_test_link,omitempty"`
	Owner              string                 `json:"owner,omitempty"`
	Priority           string                 `json:"priority,omitempty"`
	Status             string                 `json:"status,omitempty"`
	Tags               []string               `json:"tags,omitempty"`
	FurtherInformation []string               `json:"further_information,omitempty"`
	Requirements       []RequirementReference `json:"requirements,omitempty"`
}

// RequirementReference can be either a full requirement or a string reference
type RequirementReference struct {
	Full      *RequirementDetail
	Reference string
}

// UnmarshalJSON handles both full requirements and string references
func (r *RequirementReference) UnmarshalJSON(data []byte) error {
	// Try to unmarshal as string first
	var str string
	if err := json.Unmarshal(data, &str); err == nil {
		r.Reference = str
		return nil
	}

	// Otherwise, unmarshal as full requirement
	var req RequirementDetail
	if err := json.Unmarshal(data, &req); err != nil {
		return err
	}
	r.Full = &req
	return nil
}

func displayTree(config *RequirementConfig, details bool) {
	fmt.Printf("Requirements (v%s)\n", config.Version)
	if len(config.Aliases) > 0 {
		fmt.Printf("\nAliases:\n")
		for _, alias := range config.Aliases {
			fmt.Printf("  @%s → %s <%s>\n", alias.Alias, alias.Name, alias.Email)
		}
	}
	fmt.Printf("\nRequirements:\n")
	for _, req := range config.Requirements {
		displayRequirement(&req, "", details)
	}
}

func displayRequirement(req *RequirementDetail, prefix string, details bool) {
	// Display summary and basic info
	name := req.Name
	if name == "" {
		name = "unnamed"
	}

	statusSymbol := getStatusSymbol(req.Status)
	priorityColor := getPriorityIndicator(req.Priority)

	fmt.Printf("%s%s [%s] %s %s\n", prefix, statusSymbol, name, req.Summary, priorityColor)

	if details {
		if req.Owner != "" {
			fmt.Printf("%s  Owner: %s\n", prefix, req.Owner)
		}
		if req.Description != "" {
			desc := strings.Split(strings.TrimSpace(req.Description), "\n")[0]
			if len(desc) > 80 {
				desc = desc[:77] + "..."
			}
			fmt.Printf("%s  Description: %s\n", prefix, desc)
		}
		if len(req.Tags) > 0 {
			fmt.Printf("%s  Tags: %s\n", prefix, strings.Join(req.Tags, ", "))
		}
	}

	// Display sub-requirements
	for i, childRef := range req.Requirements {
		// Skip string references for now
		if childRef.Full == nil {
			continue
		}
		child := childRef.Full

		isLast := i == len(req.Requirements)-1
		var newPrefix string
		if isLast {
			newPrefix = prefix + "  └─ "
		} else {
			newPrefix = prefix + "  ├─ "
		}
		childPrefix := prefix + "     "
		if !isLast {
			childPrefix = prefix + "  │  "
		}

		// Adjust prefix for recursion
		displayRequirementWithPrefix(child, newPrefix, childPrefix, details)
	}
}

func displayRequirementWithPrefix(req *RequirementDetail, linePrefix, childPrefix string, details bool) {
	name := req.Name
	if name == "" {
		name = "unnamed"
	}

	statusSymbol := getStatusSymbol(req.Status)
	priorityColor := getPriorityIndicator(req.Priority)

	fmt.Printf("%s%s [%s] %s %s\n", linePrefix, statusSymbol, name, req.Summary, priorityColor)

	if details {
		if req.Owner != "" {
			fmt.Printf("%s  Owner: %s\n", childPrefix, req.Owner)
		}
		if req.Description != "" {
			desc := strings.Split(strings.TrimSpace(req.Description), "\n")[0]
			if len(desc) > 80 {
				desc = desc[:77] + "..."
			}
			fmt.Printf("%s  Description: %s\n", childPrefix, desc)
		}
		if len(req.Tags) > 0 {
			fmt.Printf("%s  Tags: %s\n", childPrefix, strings.Join(req.Tags, ", "))
		}
	}

	// Display sub-requirements recursively
	for i, childRef := range req.Requirements {
		// Skip string references for now
		if childRef.Full == nil {
			continue
		}
		child := childRef.Full

		isLast := i == len(req.Requirements)-1
		var newLinePrefix, newChildPrefix string
		if isLast {
			newLinePrefix = childPrefix + "└─ "
			newChildPrefix = childPrefix + "   "
		} else {
			newLinePrefix = childPrefix + "├─ "
			newChildPrefix = childPrefix + "│  "
		}
		displayRequirementWithPrefix(child, newLinePrefix, newChildPrefix, details)
	}
}

func displayTable(config *RequirementConfig) {
	fmt.Printf("%-20s %-50s %-15s %-12s %-15s\n", "ID", "Summary", "Owner", "Priority", "Status")
	fmt.Println(strings.Repeat("-", 115))

	for _, req := range config.Requirements {
		displayRequirementRow(&req)
	}
}

func displayRequirementRow(req *RequirementDetail) {
	name := req.Name
	if name == "" {
		name = "-"
	}
	summary := req.Summary
	if len(summary) > 48 {
		summary = summary[:45] + "..."
	}
	owner := req.Owner
	if owner == "" {
		owner = "-"
	}
	priority := req.Priority
	if priority == "" {
		priority = "-"
	}
	status := req.Status
	if status == "" {
		status = "-"
	}

	fmt.Printf("%-20s %-50s %-15s %-12s %-15s\n", name, summary, owner, priority, status)

	// Display sub-requirements
	for _, childRef := range req.Requirements {
		// Skip string references for now
		if childRef.Full == nil {
			continue
		}
		displayRequirementRow(childRef.Full)
	}
}

func getStatusSymbol(status string) string {
	switch status {
	case "implemented":
		return "✓"
	case "approved":
		return "○"
	case "proposed":
		return "◐"
	case "draft":
		return "◯"
	default:
		return "·"
	}
}

func getPriorityIndicator(priority string) string {
	switch priority {
	case "critical":
		return "🔴"
	case "high":
		return "🟠"
	case "medium":
		return "🟡"
	case "low":
		return "🟢"
	default:
		return ""
	}
}

func init() {
	rootCmd.AddCommand(listCmd)
	listCmd.Flags().StringVarP(&outputFormat, "format", "f", "tree", "Output format (tree, table, json)")
	listCmd.Flags().BoolVarP(&showDetails, "details", "d", false, "Show detailed information")
}
