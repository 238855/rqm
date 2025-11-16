// RQM - Requirements Management in Code
// TypeScript Type Definitions
// SPDX-License-Identifier: MIT

/**
 * Requirement priority levels
 */
export type Priority = "critical" | "high" | "medium" | "low";

/**
 * Requirement status
 */
export type Status = "draft" | "proposed" | "approved" | "implemented" | "verified" | "deprecated";

/**
 * Owner reference - can be email, GitHub handle, or alias
 */
export type Owner = string;

/**
 * Person alias definition
 */
export interface PersonAlias {
  alias: string;
  name: string;
  email?: string;
  github?: string;
}

/**
 * Core Requirement structure
 * Supports both inline requirements and reference-only requirements
 */
export interface Requirement {
  /** Unique human-readable summary */
  summary: string;

  /** Unique requirement ID (e.g., RQM-001) */
  name?: string;

  /** Detailed description of the requirement */
  description?: string;

  /** Business justification for the requirement */
  justification?: string;

  /** Acceptance test criteria (Given/When/Then format) */
  acceptance_test?: string;

  /** Link to automated acceptance test */
  acceptance_test_link?: string;

  /** Owner responsible for the requirement */
  owner?: Owner;

  /** Priority level */
  priority?: Priority;

  /** Current status */
  status?: Status;

  /** Tags for categorization and filtering */
  tags?: string[];

  /** Additional information links or notes */
  further_information?: string[];

  /** Dependencies on other requirements (by name or summary) */
  dependencies?: string[];

  /** Child requirements */
  requirements?: RequirementReference[];
}

/**
 * Requirement reference - can be either a full requirement object
 * or just a string reference (summary or name)
 */
export type RequirementReference = Requirement | string;

/**
 * Top-level requirements configuration
 */
export interface RequirementConfig {
  /** Schema version */
  version: string;

  /** Person aliases for owner references */
  aliases?: PersonAlias[];

  /** Top-level requirements list */
  requirements: RequirementReference[];

  /** Additional information about the requirements file */
  further_information?: string[];
}

/**
 * Validation result from the Rust validator
 */
export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

/**
 * Cycle check result from graph analysis
 */
export interface CycleCheckResult {
  has_cycles: boolean;
  cycles: string[][];
}

/**
 * Graph edge for visualization
 */
export interface GraphEdge {
  from: string;
  to: string;
}

/**
 * Graph data for visualization
 */
export interface GraphData {
  nodes: Requirement[];
  edges: GraphEdge[];
}
