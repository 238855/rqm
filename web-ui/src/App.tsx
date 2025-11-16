// RQM - Requirements Management in Code
// Web UI - Main Application Component
// SPDX-License-Identifier: MIT

function App() {
  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow">
        <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
          <h1 className="text-3xl font-bold tracking-tight text-gray-900">
            RQM - Requirements Management
          </h1>
          <p className="mt-2 text-sm text-gray-600">
            Requirements as Code - Visualize, Validate, and Track
          </p>
        </div>
      </header>
      <main className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
        <div className="rounded-lg bg-white p-6 shadow">
          <h2 className="text-xl font-semibold text-gray-900">Welcome to RQM</h2>
          <p className="mt-4 text-gray-600">Load a requirements file to get started.</p>
        </div>
      </main>
    </div>
  );
}

export default App;
