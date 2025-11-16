// RQM - Requirements Management in Code
// Custom Requirement Node Component
// SPDX-License-Identifier: MIT

import { memo } from "react";
import { Handle, Position, type NodeProps } from "reactflow";
import { getStatusColor, getStatusIcon, getPriorityIcon } from "../utils/requirements";
import type { Status, Priority } from "../types";

interface RequirementNodeData {
  label: string;
  summary: string;
  status?: Status;
  priority?: Priority;
  isCircular?: boolean;
}

export const RequirementNode = memo(({ data }: NodeProps<RequirementNodeData>) => {
  const statusColor = getStatusColor(data.status);

  return (
    <div
      className={`px-4 py-3 rounded-lg border-2 shadow-md min-w-[200px] ${
        data.isCircular ? "border-red-500 bg-red-50" : "border-gray-300 bg-white"
      }`}
    >
      <Handle type="target" position={Position.Left} />

      <div className="flex flex-col gap-2">
        {/* Header with priority */}
        <div className="flex items-center justify-between gap-2">
          <span className="text-xs font-semibold text-gray-500">{data.label}</span>
          {data.priority && (
            <span className="text-sm" title={data.priority}>
              {getPriorityIcon(data.priority)}
            </span>
          )}
        </div>

        {/* Summary */}
        <div className="text-sm font-medium text-gray-900">{data.summary}</div>

        {/* Status badge */}
        {data.status && (
          <div
            className={`inline-flex items-center gap-1 px-2 py-1 rounded text-xs font-medium w-fit ${statusColor}`}
          >
            <span>{getStatusIcon(data.status)}</span>
            <span>{data.status}</span>
          </div>
        )}

        {/* Circular reference warning */}
        {data.isCircular && (
          <div className="text-xs text-red-600 font-semibold">⚠️ Circular Reference</div>
        )}
      </div>

      <Handle type="source" position={Position.Right} />
    </div>
  );
});

RequirementNode.displayName = "RequirementNode";
