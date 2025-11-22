package rqmcore

// #cgo CFLAGS: -I${SRCDIR}/../../../rust-core
// #cgo darwin LDFLAGS: -L${SRCDIR}/../../../rust-core/target/release -lrqm_core -ldl -lm
// #cgo linux LDFLAGS: -L${SRCDIR}/../../../rust-core/target/release -lrqm_core -ldl -lm -lpthread
// #cgo windows LDFLAGS: -L${SRCDIR}/../../../rust-core/target/release -lrqm_core -lws2_32 -luserenv -lbcrypt
//
// #include <stdlib.h>
// #include "rqm_core.h"
import "C"
import (
	"encoding/json"
	"fmt"
	"unsafe"
)

// ValidationResult represents the result of YAML validation
type ValidationResult struct {
	Valid    bool     `json:"valid"`
	Errors   []string `json:"errors"`
	Warnings []string `json:"warnings"`
}

// ValidateYAML validates YAML content using the embedded Rust validator
// This function calls into the Rust library via CGO
func ValidateYAML(yamlContent string) (*ValidationResult, error) {
	// Convert Go string to C string
	cYaml := C.CString(yamlContent)
	defer C.free(unsafe.Pointer(cYaml))

	// Call Rust validation function
	cResult := C.validate_yaml(cYaml)
	if cResult == nil {
		return nil, fmt.Errorf("validation returned null")
	}
	defer C.free_string(cResult)

	// Convert C string back to Go string
	resultJSON := C.GoString(cResult)

	// Parse JSON result
	var result ValidationResult
	if err := json.Unmarshal([]byte(resultJSON), &result); err != nil {
		return nil, fmt.Errorf("failed to parse validation result: %w", err)
	}

	return &result, nil
}

// Available returns true if the Rust validator is available
// This allows the CLI to fall back to external validator if needed
func Available() bool {
	return true
}
