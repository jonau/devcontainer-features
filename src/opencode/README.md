# OpenCode Feature

Installs the official [OpenCode](https://opencode.ai) CLI from GitHub releases, seeds `~/.config/opencode/opencode.json`, and optionally adds helper scripts that expose the JSON template. The feature is idempotent, so you can layer it on top of any Debian/Ubuntu-based dev container.

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/OWNER/devcontainer-features/opencode:0": {
      "configTemplate": "{\n  \"workspace\": \"/workspaces/project\"\n}"
    }
  }
}
```

## What Gets Installed

- Official `opencode` binary placed in `/usr/local/bin`
- Optional `opencode-template` helper that prints the seeded JSON template
- `~/.config/opencode/opencode.json` populated with the provided template (or `{}` by default) for both `root` and the detected non-root dev user
- `/usr/local/share/opencode/default-config.json` so other tooling can reuse the template

If the config file is missing the feature writes the following message and drops in the fallback JSON, matching the behavior you outlined:

```bash
if [ ! -f "$HOME/.config/opencode/opencode.json" ]; then
  echo "No user config mounted, creating minimal fallback"
  mkdir -p "$HOME/.config/opencode"
  echo '{}' > "$HOME/.config/opencode/opencode.json"
fi
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `configTemplate` | string | `{}` | JSON content written to `~/.config/opencode/opencode.json` when the file does not exist. Also stored under `/usr/local/share/opencode/default-config.json`. |
| `installHelperScripts` | boolean | `true` | Installs the `opencode-template` helper alongside the main CLI. Set to `false` if you only need the primary `opencode` command. |
| `opencodeVersion` | string | `latest` | Version of the OpenCode CLI pulled from GitHub releases (e.g. `1.0.180`). When left as `latest`, the newest release is used. |

Options are exported as environment variables (`CONFIGTEMPLATE`, `INSTALLHELPERSCRIPTS`, `OPENCODEVERSION`) while the install script runs.
