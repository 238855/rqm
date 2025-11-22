// RQM - Requirements Management in Code
// Copyright (c) 2025
// SPDX-License-Identifier: MIT

package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
)

var (
	installFlag bool
)

var agentInstructionsCmd = &cobra.Command{
	Use:   "agent-instructions",
	Short: "Output AI agent instructions for Requirement-Driven Development",
	Long: `Generate instructions for AI coding agents (GitHub Copilot, Claude, Cursor, etc.)
on how to follow Requirement-Driven Development (RDD) workflow with RQM.

Output can be copied into .github/copilot-instructions.md or similar files.

With --install flag, automatically appends to .github/copilot-instructions.md if found.`,
	Example: `  rqm agent-instructions
  rqm agent-instructions > .github/rdd-workflow.md
  rqm agent-instructions --install`,
	RunE: runAgentInstructions,
}

func init() {
	rootCmd.AddCommand(agentInstructionsCmd)
	agentInstructionsCmd.Flags().BoolVar(&installFlag, "install", false, "Install instructions to .github/copilot-instructions.md")
}

func runAgentInstructions(cmd *cobra.Command, args []string) error {
	instructions := getInstructions()

	if installFlag {
		return installInstructions(instructions)
	}

	fmt.Print(instructions)
	return nil
}

func getInstructions() string {
	return `# AI Agent Instructions: Requirement-Driven Development (RDD)

## What is RDD?

**Requirement-Driven Development** is a workflow where:
1. Every feature/fix starts with a requirement definition
2. Requirements have acceptance criteria (tests)
3. Code is implemented to satisfy those criteria
4. Tests validate the implementation

**Benefits**: Traceability, testability, clear success criteria, living documentation.

## RDD Workflow for AI Agents

### Before Writing Code

1. **Check for requirement**: ` + "`rqm list`" + ` or search ` + "`.rqm/requirements.yml`" + `
2. **Read acceptance criteria**: Understand what "done" means
3. **Check test status**: Run acceptance test (expect failure initially)

### During Implementation

1. **Reference requirement ID** in commit messages: ` + "`feat(component): implement REQ-XXX`" + `
2. **Run validation frequently**: ` + "`rqm validate .rqm/requirements.yml`" + `
3. **Check for circular refs**: ` + "`rqm check .rqm/requirements.yml`" + `
4. **Run acceptance tests**: ` + "`./tests/acceptance/test_*.sh`" + `
5. **Update requirement status**: draft → proposed → approved → implemented

### After Implementation

1. **Verify all tests pass**: Run acceptance test for the requirement
2. **Update sub-requirements**: Mark child requirements as implemented
3. **Document in commit**: List satisfied acceptance criteria

## Key Commands

` + "```bash" + `
# View all requirements
rqm list .rqm/requirements.yml

# Validate requirements file structure
rqm validate .rqm/requirements.yml

# Check for circular references
rqm check .rqm/requirements.yml

# Visualize requirement tree
rqm serve .rqm/requirements.yml
# Then open http://localhost:3000

# Run acceptance tests
./tests/acceptance/run_all_tests.sh
` + "```" + `

## Important Files

- **Requirements**: ` + "`.rqm/requirements.yml`" + ` - All project requirements
- **Schema**: ` + "`schema.json`" + ` - YAML structure definition
- **Acceptance Tests**: ` + "`tests/acceptance/test_*.sh`" + ` - Automated validation
- **Examples**: ` + "`examples/sample-requirements.yml`" + ` - Reference format

## Requirement Structure

` + "```yaml" + `
requirements:
  - summary: "Unique requirement identifier"
    name: "REQ-001"  # Optional ID
    description: "What must be implemented"
    justification: "Why it's needed"
    acceptance_test: |
      Given: Initial state
      When: Action taken
      Then: Expected outcome
    acceptance_test_link: "tests/acceptance/test_feature.sh"
    owner: "developer@example.com"
    status: "draft|proposed|approved|implemented"
    requirements:  # Sub-requirements
      - summary: "Child requirement"
` + "```" + `

## RDD Best Practices

### DO:
- ✅ Start with the requirement, not the code
- ✅ Write failing tests first (TDD-style)
- ✅ Reference requirement IDs in commits
- ✅ Update requirement status as you progress
- ✅ Run ` + "`rqm validate`" + ` before committing
- ✅ Add sub-requirements for complex tasks
- ✅ Link to acceptance tests

### DON'T:
- ❌ Write code without a corresponding requirement
- ❌ Skip acceptance criteria
- ❌ Forget to update requirement status
- ❌ Create circular requirement dependencies
- ❌ Leave requirements in "draft" forever
- ❌ Commit without running validation

## Commit Format

` + "```" + `
feat(component): implement REQ-XXX requirement name

Satisfies REQ-XXX acceptance criteria:
- ✓ Criterion 1 description
- ✓ Criterion 2 description
- ✓ All tests pass

Acceptance test: tests/acceptance/test_feature.sh
Status: draft → implemented
` + "```" + `

## Workflow Example

` + "```bash" + `
# 1. Find requirement
rqm list | grep "user authentication"

# 2. Read full details
rqm serve .rqm/requirements.yml  # Navigate to requirement

# 3. Check current test status
./tests/acceptance/test_auth.sh  # Should fail

# 4. Implement code
# ... write implementation ...

# 5. Validate during development
rqm validate .rqm/requirements.yml
rqm check .rqm/requirements.yml

# 6. Run tests
./tests/acceptance/test_auth.sh  # Should pass

# 7. Update requirement status in .rqm/requirements.yml
# Change status: "draft" to "implemented"

# 8. Commit with reference
git commit -m "feat(auth): implement REQ-AUTH-001 user authentication

Satisfies REQ-AUTH-001 acceptance criteria:
- ✓ Users can log in with email/password
- ✓ Sessions are created with secure tokens
- ✓ Failed attempts are logged

Acceptance test: tests/acceptance/test_auth.sh"
` + "```" + `

## Quick Reference

| Task | Command |
|------|---------|
| List all requirements | ` + "`rqm list .rqm/requirements.yml`" + ` |
| Validate YAML | ` + "`rqm validate .rqm/requirements.yml`" + ` |
| Check circular refs | ` + "`rqm check .rqm/requirements.yml`" + ` |
| Visual tree | ` + "`rqm serve .rqm/requirements.yml`" + ` |
| Run all tests | ` + "`./tests/acceptance/run_all_tests.sh`" + ` |
| View schema | ` + "`cat schema.json`" + ` |

## Integration with AI Tools

**GitHub Copilot**: Add this to ` + "`.github/copilot-instructions.md`" + `
**Cursor**: Add to ` + "`.cursorrules`" + ` or workspace settings
**Claude Code**: Reference in project context
**Cline/Aider**: Include in system prompts

## Learn More

- Run ` + "`rqm --help`" + ` for all commands
- Check ` + "`README.md`" + ` for full documentation
- View ` + "`examples/sample-requirements.yml`" + ` for format examples
- Read ` + "`docs/RDD.ai.md`" + ` for detailed RDD guide

---

**Remember**: Requirements are living documents. Update them as the project evolves.
Use ` + "`rqm validate`" + ` frequently. Follow acceptance criteria strictly.
`
}

func installInstructions(instructions string) error {
	// Look for .github/copilot-instructions.md
	githubDir := ".github"
	targetFile := filepath.Join(githubDir, "copilot-instructions.md")

	// Check if .github directory exists
	if _, err := os.Stat(githubDir); os.IsNotExist(err) {
		return fmt.Errorf(".github directory not found - please create it first")
	}

	// Check if file exists
	if _, err := os.Stat(targetFile); os.IsNotExist(err) {
		return fmt.Errorf("%s not found - please create the file first", targetFile)
	}

	// Read existing content
	existingContent, err := os.ReadFile(targetFile)
	if err != nil {
		return fmt.Errorf("failed to read %s: %w", targetFile, err)
	}

	existingStr := string(existingContent)

	// Check if RDD instructions already exist
	if strings.Contains(existingStr, "Requirement-Driven Development") ||
		strings.Contains(existingStr, "RDD Workflow") ||
		strings.Contains(existingStr, "rqm validate") ||
		strings.Contains(existingStr, "rqm agent-instructions") {
		fmt.Printf("✓ %s already contains RQM/RDD instructions\n", targetFile)
		fmt.Println("No changes made (instructions already present)")
		return nil
	}

	// Append instructions
	separator := "\n\n---\n\n"
	newContent := existingStr + separator + instructions

	if err := os.WriteFile(targetFile, []byte(newContent), 0644); err != nil {
		return fmt.Errorf("failed to write to %s: %w", targetFile, err)
	}

	fmt.Printf("✓ Successfully added RDD instructions to %s\n", targetFile)
	fmt.Printf("  Added %d lines of RQM workflow guidance\n", strings.Count(instructions, "\n"))
	fmt.Println("\nAI agents will now follow Requirement-Driven Development workflow!")

	return nil
}
