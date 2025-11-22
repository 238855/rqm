// RQM - Requirements Management in Code
// Copyright (c) 2025
// SPDX-License-Identifier: MIT

package cmd

import (
	"embed"
	"fmt"
	"io/fs"
	"net/http"
	"os"
	"os/exec"
	"runtime"

	"github.com/spf13/cobra"
)

//go:embed web-dist/*
var webUI embed.FS

var (
	servePort string
	serveOpen bool
)

var serveCmd = &cobra.Command{
	Use:   "serve [requirements-file]",
	Short: "Start web UI server to visualize requirements",
	Long: `Start a local web server that serves the RQM web UI.

The web UI provides an interactive visualization of your requirements,
including:
  - Interactive requirement tree/graph view
  - Circular reference detection and visualization
  - Requirement details and relationships
  - Search and filter capabilities

If a requirements file is provided, it will be automatically loaded.`,
	Example: `  rqm serve
  rqm serve requirements.yml
  rqm serve --port 8080
  rqm serve --open requirements.yml`,
	RunE: runServe,
}

func init() {
	rootCmd.AddCommand(serveCmd)
	serveCmd.Flags().StringVarP(&servePort, "port", "p", "3000", "Port to run the server on")
	serveCmd.Flags().BoolVarP(&serveOpen, "open", "o", false, "Open browser automatically")
}

func runServe(cmd *cobra.Command, args []string) error {
	// Get the embedded filesystem
	webFS, err := fs.Sub(webUI, "web-dist")
	if err != nil {
		return fmt.Errorf("failed to access embedded web UI: %w", err)
	}

	// Serve static files
	http.Handle("/", http.FileServer(http.FS(webFS)))

	// If a requirements file was provided, serve it at /api/requirements
	if len(args) > 0 {
		reqFile := args[0]
		http.HandleFunc("/api/requirements", func(w http.ResponseWriter, r *http.Request) {
			data, err := os.ReadFile(reqFile)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/x-yaml")
			w.Write(data)
		})
		fmt.Printf("📄 Serving requirements from: %s\n", reqFile)
	}

	addr := fmt.Sprintf(":%s", servePort)
	fmt.Printf("🚀 RQM Web UI starting...\n")
	fmt.Printf("📍 Server running at: http://localhost%s\n", addr)
	fmt.Printf("Press Ctrl+C to stop\n\n")

	// Open browser if requested
	if serveOpen {
		openBrowser(fmt.Sprintf("http://localhost%s", addr))
	}

	return http.ListenAndServe(addr, nil)
}

func openBrowser(url string) {
	var cmd *exec.Cmd

	switch runtime.GOOS {
	case "darwin":
		cmd = exec.Command("open", url)
	case "linux":
		cmd = exec.Command("xdg-open", url)
	case "windows":
		cmd = exec.Command("cmd", "/c", "start", url)
	default:
		fmt.Printf("Please open your browser to: %s\n", url)
		return
	}

	if err := cmd.Start(); err != nil {
		fmt.Printf("Failed to open browser: %v\n", err)
		fmt.Printf("Please open your browser to: %s\n", url)
	}
}
