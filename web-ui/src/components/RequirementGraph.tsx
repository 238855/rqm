// RQM - Requirements Management in Code
// Graph Visualization Component
// SPDX-License-Identifier: MIT

import { useCallback, useMemo } from "react";
import {
  ReactFlow,
  type Node,
  type Edge,
  Background,
  Controls,
  MiniMap,
  useNodesState,
  useEdgesState,
  MarkerType,
  type OnNodesChange,
  type OnEdgesChange,
} from "reactflow";
import "reactflow/dist/style.css";
import type { RequirementConfig, RequirementReference } from "../types";
import { isRequirement } from "../utils/requirements";

interface RequirementGraphProps {
  config: RequirementConfig;
  onNodeClick?: (requirementId: string) => void;
}

interface NodeData {
  label: string;
  summary: string;
  status?: string;
  priority?: string;
}

/**
 * Convert requirements to React Flow nodes and edges
 */
function requirementsToGraph(
  requirements: RequirementReference[],
  parentId: string | null = null,
  visited: Set<string> = new Set(),
  depth: number = 0
): { nodes: Node<NodeData>[]; edges: Edge[] } {
  const nodes: Node<NodeData>[] = [];
  const edges: Edge[] = [];
  const maxDepth = 10; // Prevent infinite loops

  if (depth > maxDepth) {
    return { nodes, edges };
  }

  requirements.forEach((ref, index) => {
    if (!isRequirement(ref)) {
      // String reference - create a simple node
      const nodeId = `ref-${parentId}-${index}`;
      nodes.push({
        id: nodeId,
        type: "default",
        position: { x: depth * 250, y: index * 100 },
        data: {
          label: ref,
          summary: ref,
        },
      });

      if (parentId) {
        edges.push({
          id: `${parentId}-${nodeId}`,
          source: parentId,
          target: nodeId,
          markerEnd: { type: MarkerType.ArrowClosed },
        });
      }
      return;
    }

    const nodeId = ref.name || ref.summary;

    // Check for circular reference
    const isCircular = visited.has(nodeId);

    nodes.push({
      id: nodeId,
      type: isCircular ? "default" : "default",
      position: { x: depth * 250, y: index * 100 },
      data: {
        label: ref.name || ref.summary,
        summary: ref.summary,
        status: ref.status,
        priority: ref.priority,
      },
      style: {
        background: isCircular ? "#fee2e2" : "#fff",
        border: isCircular ? "2px solid #dc2626" : "1px solid #e5e7eb",
        borderRadius: "8px",
        padding: "10px",
        fontSize: "12px",
        width: 200,
      },
    });

    if (parentId) {
      edges.push({
        id: `${parentId}-${nodeId}`,
        source: parentId,
        target: nodeId,
        markerEnd: { type: MarkerType.ArrowClosed },
        style: isCircular ? { stroke: "#dc2626" } : undefined,
        label: isCircular ? "⚠️ Circular" : undefined,
      });
    }

    // Process children if not circular
    if (!isCircular && ref.requirements) {
      visited.add(nodeId);
      const childGraph = requirementsToGraph(ref.requirements, nodeId, new Set(visited), depth + 1);
      nodes.push(...childGraph.nodes);
      edges.push(...childGraph.edges);
    }
  });

  return { nodes, edges };
}

/**
 * Apply automatic layout to nodes
 */
function applyLayout(nodes: Node<NodeData>[]): Node<NodeData>[] {
  // Simple hierarchical layout
  const layerWidth = 250;
  const nodeHeight = 100;
  const layerCounts = new Map<number, number>();

  return nodes.map((node) => {
    const layer = Math.floor(node.position.x / layerWidth);
    const count = layerCounts.get(layer) || 0;
    layerCounts.set(layer, count + 1);

    return {
      ...node,
      position: {
        x: layer * layerWidth,
        y: count * nodeHeight,
      },
    };
  });
}

export function RequirementGraph({ config, onNodeClick }: RequirementGraphProps) {
  const { nodes: initialNodes, edges: initialEdges } = useMemo(() => {
    const graph = requirementsToGraph(config.requirements);
    return {
      nodes: applyLayout(graph.nodes),
      edges: graph.edges,
    };
  }, [config]);

  const [nodes, , onNodesChange] = useNodesState(initialNodes);
  const [edges, , onEdgesChange] = useEdgesState(initialEdges);

  const handleNodeClick = useCallback(
    (_event: React.MouseEvent, node: Node) => {
      onNodeClick?.(node.id);
    },
    [onNodeClick]
  );

  return (
    <div className="w-full h-full">
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange as OnNodesChange}
        onEdgesChange={onEdgesChange as OnEdgesChange}
        onNodeClick={handleNodeClick}
        fitView
        attributionPosition="bottom-left"
      >
        <Background />
        <Controls />
        <MiniMap
          nodeStrokeWidth={3}
          zoomable
          pannable
          style={{
            background: "#f9fafb",
          }}
        />
      </ReactFlow>
    </div>
  );
}
