# Requirement-Driven Development (RDD) Workflow

**RQM practices what it preaches: using requirements to drive development**

## The RDD Flow

```
1. Define Requirement → 2. Write Acceptance Test → 3. Implement Code → 4. Pass Test
                                    ↓
                          Add Sub-Requirements (repeat)
```

## Directory Structure

```
.rqm/
  requirements.yml          # Root requirements for the project

tests/
  acceptance/              # Automated acceptance tests
    test_*.sh             # Bash-based acceptance tests
    fixtures/             # Test data files
```

## Workflow Steps

### 1. Create Requirement

Add to `.rqm/requirements.yml`:

```yaml
- summary: Feature Name
  name: REQ-ID
  description: What the feature does
  justification: Why we need it
  acceptance_test: |
    Given [context]
    When [action]
    Then [expected result]
  acceptance_test_link: https://github.com/.../tests/acceptance/test_feature.sh
  owner: developer
  priority: high
  status: draft
  tags:
    - component
```

### 2. Write Acceptance Test

Create `tests/acceptance/test_feature.sh`:

```bash
#!/usr/bin/env bash
# REQ-ID: Feature Name Acceptance Test

# Test that demonstrates the requirement is satisfied
# Should be executable and return 0 on success
```

### 3. Run Test (Expect Failure)

```bash
./tests/acceptance/test_feature.sh
# Should fail initially - this is TDD/BDD
```

### 4. Implement Code

Write the minimum code to pass the acceptance test:

- Update Rust core
- Add CLI commands
- Update UI components

### 5. Add Sub-Requirements

As you implement, break down into smaller requirements:

```yaml
requirements:
  - summary: Sub-requirement 1
    name: REQ-ID.1
    description: Specific technical detail
    acceptance_test: More granular test
    status: implemented
```

### 6. Iterate

Repeat for each sub-requirement until the parent requirement's acceptance test passes.

## Current RQM Requirements

See `.rqm/requirements.yml` for RQM's own requirements.

Key requirements:

- **RQM-001**: YAML File Validation
- **RQM-002**: Circular Reference Detection
- **RQM-003**: CLI Validation Command
- **RQM-004**: RDD Support

## Running Acceptance Tests

```bash
# Run all acceptance tests
find tests/acceptance -name 'test_*.sh' -exec {} \;

# Run specific test
./tests/acceptance/test_validation.sh
```

## Test Status

Acceptance tests show current implementation status:

- ✓ PASS = Requirement satisfied
- ✗ FAIL = Work needed

Example output:

```
RQM-001: YAML File Validation
✓ PASS: Valid YAML file passes validation
✗ FAIL: Duplicate summaries should fail validation
```

## Benefits of RDD

1. **Traceability**: Every line of code traces to a requirement
2. **Acceptance Criteria**: Clear definition of "done"
3. **Living Documentation**: Requirements file is always current
4. **Test-Driven**: Acceptance tests drive implementation
5. **Incremental**: Break down work into manageable chunks

## Integration with Development

### Before Coding

1. Review `.rqm/requirements.yml`
2. Identify next requirement to implement
3. Check acceptance test exists
4. Understand acceptance criteria

### During Coding

1. Run acceptance test frequently
2. Add sub-requirements as needed
3. Update requirement status
4. Keep tests passing

### After Coding

1. Ensure acceptance test passes
2. Update requirement status to `implemented`
3. Commit with reference to requirement ID
4. Link commits to requirements

## Commit Message Format

```
feat(component): implement REQ-ID requirement name

Satisfies RQM-001 acceptance criteria:
- ✓ Validation passes for valid files
- ✓ Detects duplicate summaries
- ✓ Validates owner references

Acceptance test: tests/acceptance/test_validation.sh
```

## RQM Self-Hosting

RQM uses itself to manage its own requirements, demonstrating:

- The system works for real projects
- Requirements can be complex (nested, circular references)
- The workflow is practical for daily development

---

_This workflow is itself a requirement: RQM-004_
