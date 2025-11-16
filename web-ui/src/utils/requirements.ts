// RQM - Requirements Management in Code
// Utility Functions
// SPDX-License-Identifier: MIT

import type {
  Requirement,
  RequirementReference,
  RequirementConfig,
  Priority,
  Status,
} from "../types";

/**
 * Check if a requirement reference is a full requirement object
 */
export function isRequirement(ref: RequirementReference): ref is Requirement {
  return typeof ref === "object" && ref !== null && "summary" in ref;
}

/**
 * Flatten nested requirements into a flat array
 */
export function flattenRequirements(requirements: RequirementReference[]): Requirement[] {
  const result: Requirement[] = [];

  function traverse(ref: RequirementReference) {
    if (isRequirement(ref)) {
      result.push(ref);
      if (ref.requirements) {
        ref.requirements.forEach(traverse);
      }
    }
  }

  requirements.forEach(traverse);
  return result;
}

/**
 * Find a requirement by name or summary
 */
export function findRequirement(
  config: RequirementConfig,
  identifier: string
): Requirement | undefined {
  const allRequirements = flattenRequirements(config.requirements);
  return allRequirements.find((req) => req.name === identifier || req.summary === identifier);
}

/**
 * Get all requirement names/IDs
 */
export function getAllRequirementNames(config: RequirementConfig): string[] {
  const allRequirements = flattenRequirements(config.requirements);
  return allRequirements.filter((req) => req.name).map((req) => req.name as string);
}

/**
 * Get priority color class for Tailwind
 */
export function getPriorityColor(priority?: Priority): string {
  switch (priority) {
    case "critical":
      return "text-red-600 bg-red-50";
    case "high":
      return "text-orange-600 bg-orange-50";
    case "medium":
      return "text-yellow-600 bg-yellow-50";
    case "low":
      return "text-green-600 bg-green-50";
    default:
      return "text-gray-600 bg-gray-50";
  }
}

/**
 * Get status color class for Tailwind
 */
export function getStatusColor(status?: Status): string {
  switch (status) {
    case "draft":
      return "text-gray-600 bg-gray-100";
    case "proposed":
      return "text-blue-600 bg-blue-100";
    case "approved":
      return "text-indigo-600 bg-indigo-100";
    case "implemented":
      return "text-green-600 bg-green-100";
    case "verified":
      return "text-emerald-600 bg-emerald-100";
    case "deprecated":
      return "text-red-600 bg-red-100";
    default:
      return "text-gray-600 bg-gray-100";
  }
}

/**
 * Get status icon
 */
export function getStatusIcon(status?: Status): string {
  switch (status) {
    case "draft":
      return "○";
    case "proposed":
      return "◐";
    case "approved":
      return "◑";
    case "implemented":
      return "✓";
    case "verified":
      return "✓✓";
    case "deprecated":
      return "✗";
    default:
      return "○";
  }
}

/**
 * Get priority icon/emoji
 */
export function getPriorityIcon(priority?: Priority): string {
  switch (priority) {
    case "critical":
      return "🔴";
    case "high":
      return "🟠";
    case "medium":
      return "🟡";
    case "low":
      return "🟢";
    default:
      return "⚪";
  }
}

/**
 * Count requirements by status
 */
export function countByStatus(config: RequirementConfig): Record<Status | "total", number> {
  const allRequirements = flattenRequirements(config.requirements);
  const counts: Record<string, number> = {
    draft: 0,
    proposed: 0,
    approved: 0,
    implemented: 0,
    verified: 0,
    deprecated: 0,
    total: allRequirements.length,
  };

  allRequirements.forEach((req) => {
    const status = req.status || "draft";
    counts[status] = (counts[status] || 0) + 1;
  });

  return counts as Record<Status | "total", number>;
}

/**
 * Count requirements by priority
 */
export function countByPriority(config: RequirementConfig): Record<Priority | "total", number> {
  const allRequirements = flattenRequirements(config.requirements);
  const counts: Record<string, number> = {
    critical: 0,
    high: 0,
    medium: 0,
    low: 0,
    total: allRequirements.length,
  };

  allRequirements.forEach((req) => {
    const priority = req.priority || "medium";
    counts[priority] = (counts[priority] || 0) + 1;
  });

  return counts as Record<Priority | "total", number>;
}
