//go:build cgo
// +build cgo

package cmd

import "github.com/238855/rqm/go-cli/pkg/rqmcore"

func init() {
	// Wire up the embedded validator when CGO is available
	embeddedValidator = &validatorWrapper{}
}

// validatorWrapper implements the interface expected by validate.go
type validatorWrapper struct{}

func (v *validatorWrapper) ValidateYAML(content string) (*ValidationResult, error) {
	result, err := rqmcore.ValidateYAML(content)
	if err != nil {
		return nil, err
	}
	return &ValidationResult{
		Valid:    result.Valid,
		Errors:   result.Errors,
		Warnings: result.Warnings,
	}, nil
}

func (v *validatorWrapper) Available() bool {
	return rqmcore.Available()
}
