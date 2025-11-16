# RQM Go CLI

Command-line interface for RQM (Requirements Management in Code).

## Installation

```bash
go install github.com/238855/rqm/go-cli@latest
```

## Building from Source

```bash
cd go-cli
go build -o rqm
# Optional: create requim alias
ln -sf rqm requim
```

## Usage

The CLI is available as both `rqm` and `requim`.

### Validate a requirements file

```bash
rqm validate requirements.yml
```

### Get help

```bash
rqm --help
```

## Commands

- `validate` - Validate a requirements YAML file against the schema

More commands coming soon!

## Configuration

Create a `.rqm.yaml` file in your home directory for custom configuration.

```yaml
verbose: true
```

## Version

Current version: 0.1.0
