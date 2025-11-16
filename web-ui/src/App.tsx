// RQM - Requirements Management in Code
// Web UI - Main Application Component
// SPDX-License-Identifier: MIT

import { useState } from "react";
import { RequirementGraph } from "./components/RequirementGraph";
import type { RequirementConfig } from "./types";

// Sample data for development
const sampleConfig: RequirementConfig = {
  version: "1.0",
  requirements: [
    {
      summary: "System must support requirements as code",
      name: "RQM-001",
      status: "approved",
      priority: "critical",
      requirements: [
        {
          summary: "YAML parser must validate against schema",
          name: "RQM-002",
          status: "implemented",
          priority: "high",
        },
        {
          summary: "Support nested requirement hierarchies",
          name: "RQM-003",
          status: "implemented",
          priority: "high",
          requirements: [
            {
              summary: "Detect circular references",
              name: "RQM-004",
              status: "implemented",
              priority: "critical",
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
      requirements: [
        {
          summary: "Validate command",
          name: "RQM-006",
          status: "implemented",
          priority: "medium",
        },
        {
          summary: "Graph command",
          name: "RQM-007",
          status: "implemented",
          priority: "medium",
        },
      ],
    },
  ],
};

function App() {
  const [selectedNode, setSelectedNode] = useState<string | null>(null);

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
        <aside className="w-64 bg-white border-r border-gray-200 overflow-y-auto">
          <div className="p-4">
            <h2 className="text-sm font-semibold text-gray-900 mb-3">Requirements</h2>
            <div className="space-y-2">
              <div className="text-sm text-gray-600">Total: {sampleConfig.requirements.length}</div>
              {selectedNode && (
                <div className="mt-4 p-3 bg-blue-50 border border-blue-200 rounded text-sm">
                  <div className="font-semibold text-blue-900">Selected:</div>
                  <div className="text-blue-700">{selectedNode}</div>
                </div>
              )}
            </div>
          </div>
        </aside>

        {/* Graph View */}
        <main className="flex-1 relative">
          <RequirementGraph config={sampleConfig} onNodeClick={setSelectedNode} />
        </main>
      </div>
    </div>
  );
}

export default App;
