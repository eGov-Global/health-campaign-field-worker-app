# health_campaign_field_worker_app

## Run by environment

This app supports environment-specific runs using `--dart-define=ENV_FILE=...`.

Examples:

- Dev: `fvm flutter run --dart-define=ENV_FILE=.env.dev`
- UAT: `fvm flutter run --dart-define=ENV_FILE=.env.uat`
- Prod: `fvm flutter run --dart-define=ENV_FILE=.env.prod`

From repository root, you can also use:

- `make run-dev`
- `make run-uat`
- `make run-prod`

## VS Code debug configurations

Use `.vscode/launch.json` configurations for:

- Dev Debug / UAT Debug / Prod Debug
- Dev Release / UAT Release / Prod Release

VS Code is configured to use the same FVM SDK as `make` via `.vscode/settings.json` (`.fvm/flutter_sdk`).
