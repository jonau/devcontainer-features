
# OpenCode (opencode)

Installs the OpenCode v2 CLI, seeds ~/.config/opencode/opencode.json, and ships helper scripts for working with the config.

## Example Usage

```json
"features": {
    "ghcr.io/jonau/devcontainer-features/opencode:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| configTemplate | JSON content written to ~/.config/opencode/opencode.json when the file is missing. | string | {} |
| installHelperScripts | Installs the opencode-template helper alongside the main CLI. | boolean | true |
| opencodeVersion | Version of the OpenCode CLI to install (e.g. 2.1.2). Defaults to the latest release. | string | latest |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/jonau/devcontainer-features/blob/main/src/opencode/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
