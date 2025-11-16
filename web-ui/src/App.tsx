// RQM - Requirements Management in Code
// Web UI - Main Application Component
// SPDX-License-Identifier: MIT

import { useState } from "react";
import { RequirementGraph } from "./components/RequirementGraph";
import { RequirementBrowser } from "./components/RequirementBrowser";
import type { RequirementConfig, Requirement } from "./types";

// Sample data for development
const sampleConfig: RequirementConfig = {
  version: "1.0",
  requirements: [
    {
      summary: "System must support requirements as code",
      name: "RQM-001",
      status: "approved",
      priority: "critical",
      description:
        "The system shall provide a way to manage requirements as YAML files in version control.",
      requirements: [
        {
          summary: "YAML parser must validate against schema",
          name: "RQM-002",
          status: "implemented",
          priority: "high",
          description: "All YAML files must validate against the JSON Schema.",
        },
        {
          summary: "Support nested requirement hierarchies",
          name: "RQM-003",
          status: "implemented",
          priority: "high",
          description: "Requirements can have sub-requirements to arbitrary depth.",
          requirements: [
            {
              summary: "Detect circular references",
              name: "RQM-004",
              status: "implemented",
              priority: "critical",
              description: "System must detect and warn about circular requirement dependencies.",
            },
          ],
        },
      ],
    },
    {
      summary: "Provide CLI interface",
      name: "RQM-005",
      status: "implemented",
      priority: "high",
      description: "Command-line tools for validating and managing requirements.",
      requirements: [
        {
          summary: "Validate command",
          name: "RQM-006",
          status: "implemented",
          priority: "medium",
          description: "CLI command to validate YAML files against schema.",
        },
        {
          summary: "Graph command",
          name: "RQM-007",
          status: "implemented",
          priority: "medium",
          description: "CLI command to visualize requirement graphs and detect cycles.",
        },
      ],
    },
  ],
};

type ViewMode = "graph" | "browser";

function App() {
  const [selectedNode, setSelectedNode] = useState<string | null>(null);
  const [selectedRequirement, setSelectedRequirement] = useState<Requirement | null>(null);
  const [viewMode, setViewMode] = useState<ViewMode>("graph");

  const handleRequirementSelect = (req: Requirement) => {
    setSelectedRequirement(req);
    setSelectedNode(req.name || req.summary);
  };

  return (
    <div className="flex flex-col h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 px-6 py-4 shadow-sm">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">RQM</h1>
            <p className="text-sm text-gray-600">Requirements Management in Code</p>
          </div>
          <div className="flex gap-2">
            <div className="flex gap-1 mr-4">
              <button
                onClick={() => setViewMode("graph")}
                className={`px-3 py-2 text-sm font-medium rounded-md ${
                  viewMode === "graph"
                    ? "bg-blue-600 text-white"
                    : "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
                }`}
              >
                Graph
              </button>
              <button
                onClick={() => setViewMode("browser")}
                className={`px-3 py-2 text-sm font-medium rounded-md ${
                  viewMode === "browser"
                    ? "bg-blue-600 text-white"
                    : "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
                }`}
              >
                Browser
              </button>
            </div>
            <button className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50">
              Load File
            </button>
            <button className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700">
              Validate
            </button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <div className="flex flex-1 overflow-hidden">
        {/* Sidebar */}
        <aside className="w-80 bg-white border-r border-gray-200 overflow-hidden flex flex-col">
          {viewMode === "graph" ? (
            <div className="p-4 flex-1 overflow-y-auto">
              <h2 className="text-sm font-semibold text-gray-900 mb-3">Selection</h2>
              <div className="space-y-2">
                <div className="text-sm text-gray-600">
                  Total: {sampleConfig.requirements.length}
                </div>
                {selectedRequirement ? (
                  <div className="mt-4 p-4 bg-blue-50 border border-blue-200 rounded">
                    <div className="font-semibold text-blue-900 text-sm mb-2">
                      {selectedRequirement.name || selectedRequirement.summary}
                    </div>
                    <div className="text-sm text-gray-900 mb-2">{selectedRequirement.summary}</div>
                    {selectedRequirement.description && (
                      <p className="text-xs text-gray-600">{selectedRequirement.description}</p>
                    )}
                    {selectedRequirement.status && (
                      <div className="mt-2 text-xs">
                        <span className="font-medium">Status:</span> {selectedRequirement.status}
                      </div>
                    )}
                    {selectedRequirement.priority && (
                      <div className="text-xs">
                        <span className="font-medium">Priority:</span>{" "}
                        {selectedRequirement.priority}
                      </div>
                    )}
                  </div>
                ) : (
                  <div className="text-sm text-gray-500 italic">Click a node to see details</div>
                )}
              </div>
            </div>
          ) : (
            <RequirementBrowser
              requirements={sampleConfig.requirements}
              onSelect={handleRequirementSelect}
              selectedId={selectedNode || undefined}
            />
          )}
        </aside>

        {/* Main View */}
        <main className="flex-1 relative">
          {viewMode === "graph" ? (
            <RequirementGraph
              config={sampleConfig}
              onNodeClick={(id) => {
                setSelectedNode(id);
                // Find the requirement by ID
                const flatten = (refs: typeof sampleConfig.requirements): Requirement[] => {
                  const result: Requirement[] = [];
                  refs.forEach((ref) => {
                    if (typeof ref === "object" && ref !== null && "summary" in ref) {
                      result.push(ref);
                      if (ref.requirements) {
                        result.push(...flatten(ref.requirements));
                      }
                    }
                  });
                  return result;
                };
                const all = flatten(sampleConfig.requirements);
                const req = all.find((r) => r.name === id || r.summary === id);
                setSelectedRequirement(req || null);
              }}
            />
          ) : (
            <div className="h-full flex items-center justify-center bg-white">
              <div className="text-center">
                <h2 className="text-lg font-semibold text-gray-900 mb-2">Requirement Details</h2>
                {selectedRequirement ? (
                  <div className="max-w-2xl p-6 bg-gray-50 rounded-lg">
                    <h3 className="text-xl font-bold text-gray-900 mb-2">
                      {selectedRequirement.name || selectedRequirement.summary}
                    </h3>
                    <p className="text-gray-700 mb-4">{selectedRequirement.summary}</p>
                    {selectedRequirement.description && (
                      <p className="text-gray-600 mb-4">{selectedRequirement.description}</p>
                    )}
                    <div className="flex gap-4 justify-center text-sm">
                      {selectedRequirement.status && (
                        <div>
                          <span className="font-medium">Status:</span> {selectedRequirement.status}
                        </div>
                      )}
                      {selectedRequirement.priority && (
                        <div>
                          <span className="font-medium">Priority:</span>{" "}
                          {selectedRequirement.priority}
                        </div>
                      )}
                    </div>
                  </div>
                ) : (
                  <p className="text-gray-500">Select a requirement from the browser</p>
                )}
              </div>
            </div>
          )}
        </main>
      </div>
    </div>
  );
}

export default App;
