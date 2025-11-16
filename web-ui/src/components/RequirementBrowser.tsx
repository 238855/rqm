// RQM - Requirements Management in Code
// Requirement Browser Component
// SPDX-License-Identifier: MIT

import { useState, useMemo } from "react";
import type { Requirement, RequirementReference, Priority, Status } from "../types";
import {
  flattenRequirements,
  isRequirement,
  getStatusColor,
  getStatusIcon,
  getPriorityIcon,
} from "../utils/requirements";

interface RequirementBrowserProps {
  requirements: RequirementReference[];
  onSelect?: (requirement: Requirement) => void;
  selectedId?: string;
}

type SortField = "name" | "status" | "priority";
type ViewMode = "tree" | "list";

export function RequirementBrowser({
  requirements,
  onSelect,
  selectedId,
}: RequirementBrowserProps) {
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<Status | "all">("all");
  const [priorityFilter, setPriorityFilter] = useState<Priority | "all">("all");
  const [sortField, setSortField] = useState<SortField>("name");
  const [viewMode, setViewMode] = useState<ViewMode>("tree");

  const allRequirements = useMemo(() => flattenRequirements(requirements), [requirements]);

  const filteredRequirements = useMemo(() => {
    return allRequirements.filter((req) => {
      // Search filter
      if (searchQuery) {
        const query = searchQuery.toLowerCase();
        const matchesSearch =
          req.summary.toLowerCase().includes(query) ||
          req.name?.toLowerCase().includes(query) ||
          req.description?.toLowerCase().includes(query);
        if (!matchesSearch) return false;
      }

      // Status filter
      if (statusFilter !== "all" && req.status !== statusFilter) {
        return false;
      }

      // Priority filter
      if (priorityFilter !== "all" && req.priority !== priorityFilter) {
        return false;
      }

      return true;
    });
  }, [allRequirements, searchQuery, statusFilter, priorityFilter]);

  const sortedRequirements = useMemo(() => {
    return [...filteredRequirements].sort((a, b) => {
      switch (sortField) {
        case "name":
          return (a.name || a.summary).localeCompare(b.name || b.summary);
        case "status":
          return (a.status || "draft").localeCompare(b.status || "draft");
        case "priority": {
          const priorityOrder = { critical: 0, high: 1, medium: 2, low: 3 };
          return (
            (priorityOrder[a.priority || "medium"] || 2) -
            (priorityOrder[b.priority || "medium"] || 2)
          );
        }
        default:
          return 0;
      }
    });
  }, [filteredRequirements, sortField]);

  return (
    <div className="flex flex-col h-full bg-white">
      {/* Search and Filters */}
      <div className="border-b border-gray-200 p-4 space-y-3">
        {/* Search */}
        <input
          type="text"
          placeholder="Search requirements..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        />

        {/* Filters */}
        <div className="flex gap-2">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as Status | "all")}
            className="flex-1 px-2 py-1 border border-gray-300 rounded text-xs"
          >
            <option value="all">All Status</option>
            <option value="draft">Draft</option>
            <option value="proposed">Proposed</option>
            <option value="approved">Approved</option>
            <option value="implemented">Implemented</option>
            <option value="verified">Verified</option>
            <option value="deprecated">Deprecated</option>
          </select>

          <select
            value={priorityFilter}
            onChange={(e) => setPriorityFilter(e.target.value as Priority | "all")}
            className="flex-1 px-2 py-1 border border-gray-300 rounded text-xs"
          >
            <option value="all">All Priority</option>
            <option value="critical">Critical</option>
            <option value="high">High</option>
            <option value="medium">Medium</option>
            <option value="low">Low</option>
          </select>
        </div>

        {/* Sort and View Mode */}
        <div className="flex gap-2 items-center">
          <select
            value={sortField}
            onChange={(e) => setSortField(e.target.value as SortField)}
            className="flex-1 px-2 py-1 border border-gray-300 rounded text-xs"
          >
            <option value="name">Sort by Name</option>
            <option value="status">Sort by Status</option>
            <option value="priority">Sort by Priority</option>
          </select>

          <div className="flex gap-1">
            <button
              onClick={() => setViewMode("tree")}
              className={`px-2 py-1 text-xs rounded ${
                viewMode === "tree" ? "bg-blue-600 text-white" : "bg-gray-200 text-gray-700"
              }`}
            >
              Tree
            </button>
            <button
              onClick={() => setViewMode("list")}
              className={`px-2 py-1 text-xs rounded ${
                viewMode === "list" ? "bg-blue-600 text-white" : "bg-gray-200 text-gray-700"
              }`}
            >
              List
            </button>
          </div>
        </div>

        {/* Results count */}
        <div className="text-xs text-gray-500">
          {filteredRequirements.length} of {allRequirements.length} requirements
        </div>
      </div>

      {/* Requirement List */}
      <div className="flex-1 overflow-y-auto">
        {viewMode === "list" ? (
          <RequirementList
            requirements={sortedRequirements}
            onSelect={onSelect}
            selectedId={selectedId}
          />
        ) : (
          <RequirementTree
            requirements={requirements}
            onSelect={onSelect}
            selectedId={selectedId}
            searchQuery={searchQuery}
          />
        )}
      </div>
    </div>
  );
}

interface RequirementListProps {
  requirements: Requirement[];
  onSelect?: (requirement: Requirement) => void;
  selectedId?: string;
}

function RequirementList({ requirements, onSelect, selectedId }: RequirementListProps) {
  if (requirements.length === 0) {
    return <div className="p-4 text-center text-sm text-gray-500">No requirements found</div>;
  }

  return (
    <div className="divide-y divide-gray-200">
      {requirements.map((req) => (
        <RequirementItem
          key={req.name || req.summary}
          requirement={req}
          onSelect={onSelect}
          isSelected={selectedId === req.name || selectedId === req.summary}
        />
      ))}
    </div>
  );
}

interface RequirementTreeProps {
  requirements: RequirementReference[];
  onSelect?: (requirement: Requirement) => void;
  selectedId?: string;
  searchQuery?: string;
  depth?: number;
}

function RequirementTree({
  requirements,
  onSelect,
  selectedId,
  searchQuery = "",
  depth = 0,
}: RequirementTreeProps) {
  return (
    <div>
      {requirements.map((ref, index) => {
        if (!isRequirement(ref)) {
          return (
            <div
              key={index}
              className="px-4 py-2 text-sm text-gray-500 italic"
              style={{ paddingLeft: `${depth * 20 + 16}px` }}
            >
              → {ref}
            </div>
          );
        }

        const matches =
          !searchQuery ||
          ref.summary.toLowerCase().includes(searchQuery.toLowerCase()) ||
          ref.name?.toLowerCase().includes(searchQuery.toLowerCase());

        return (
          <div key={ref.name || ref.summary}>
            <RequirementItem
              requirement={ref}
              onSelect={onSelect}
              isSelected={selectedId === ref.name || selectedId === ref.summary}
              depth={depth}
              dimmed={!matches}
            />
            {ref.requirements && ref.requirements.length > 0 && (
              <RequirementTree
                requirements={ref.requirements}
                onSelect={onSelect}
                selectedId={selectedId}
                searchQuery={searchQuery}
                depth={depth + 1}
              />
            )}
          </div>
        );
      })}
    </div>
  );
}

interface RequirementItemProps {
  requirement: Requirement;
  onSelect?: (requirement: Requirement) => void;
  isSelected?: boolean;
  depth?: number;
  dimmed?: boolean;
}

function RequirementItem({
  requirement,
  onSelect,
  isSelected = false,
  depth = 0,
  dimmed = false,
}: RequirementItemProps) {
  const statusColor = getStatusColor(requirement.status);

  return (
    <button
      onClick={() => onSelect?.(requirement)}
      className={`w-full text-left px-4 py-3 hover:bg-gray-50 transition-colors ${
        isSelected ? "bg-blue-50 border-l-4 border-blue-600" : ""
      } ${dimmed ? "opacity-40" : ""}`}
      style={{ paddingLeft: `${depth * 20 + 16}px` }}
    >
      <div className="space-y-2">
        {/* Header */}
        <div className="flex items-start justify-between gap-2">
          <div className="flex-1 min-w-0">
            {requirement.name && (
              <div className="text-xs font-mono text-gray-500">{requirement.name}</div>
            )}
            <div className="text-sm font-medium text-gray-900 truncate">{requirement.summary}</div>
          </div>
          <div className="flex-shrink-0">
            {requirement.priority && (
              <span title={requirement.priority}>{getPriorityIcon(requirement.priority)}</span>
            )}
          </div>
        </div>

        {/* Description */}
        {requirement.description && (
          <p className="text-xs text-gray-600 line-clamp-2">{requirement.description}</p>
        )}

        {/* Meta */}
        <div className="flex items-center gap-2 flex-wrap">
          {requirement.status && (
            <span
              className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs ${statusColor}`}
            >
              {getStatusIcon(requirement.status)}
              <span>{requirement.status}</span>
            </span>
          )}
          {requirement.owner && (
            <span className="text-xs text-gray-500">
              👤 {typeof requirement.owner === "string" ? requirement.owner : ""}
            </span>
          )}
        </div>
      </div>
    </button>
  );
}
