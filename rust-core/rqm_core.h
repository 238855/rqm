// RQM Core C Header
// FFI interface for Go CGO integration

#ifndef RQM_CORE_H
#define RQM_CORE_H

#ifdef __cplusplus
extern "C" {
#endif

// Validate YAML content and return JSON result
// Returns: JSON string (must be freed with free_string)
char* validate_yaml(const char* yaml_content);

// Free a string allocated by Rust
void free_string(char* s);

#ifdef __cplusplus
}
#endif

#endif // RQM_CORE_H
