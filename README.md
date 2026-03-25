# OpenCode Dev Container Features

Custom [dev container Features](https://containers.dev/implementors/features/) for the OpenCode toolchain. The repository already exposes one feature (`opencode`) and is structured so additional, unrelated features can be dropped into `src/<feature-name>` without touching existing code.

## Repository Layout

- `src/<feature>` – every feature owns its `devcontainer-feature.json`, `install.sh`, docs, and optional assets
- `test/<feature>` – per-feature scenarios and smoke tests executed with `devcontainer features test`

Add a new feature by copying the `src/opencode` folder into `src/<new-feature>`, adjusting metadata, and creating matching tests under `test/<new-feature>`.

## Developing Locally

```bash
devcontainer features test .
```

The command uses the scenarios defined in `test/**/scenarios.json` to build disposable containers and run the bash tests sitting next to them. This keeps the repo ready for future features without any extra setup.

## Publishing

Once you're happy with a feature, push the repo to GitHub and reference it from a devcontainer using the `ghcr.io/<owner>/<repo>/<feature>:<version>` notation. Each feature version is controlled independently inside its own `devcontainer-feature.json`.
