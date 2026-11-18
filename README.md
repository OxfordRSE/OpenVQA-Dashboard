# OpenVQA Dashboard

A minimal Shiny application using bslib for layout and golem for the app
launcher. The R package name is `openvqadashboard`.

## Run locally

For first-time setup, from the repository root:

```sh
rv sync
cp config-template.yaml config.yaml
# Edit config.yaml before launching.
Rscript dev/run_dev.R
```

Copy the template once. For subsequent launches, run `Rscript dev/run_dev.R`
without copying it again.

Open the local URL printed by Shiny. Stop the server with Ctrl+C.
In an R console started in this directory, use `source("dev/run_dev.R")`.
The development script sources the app files directly, so no package
installation or documentation generation is needed while developing.

## Settings

Configuration is split between shared defaults and installation-specific settings:

| File | Purpose | Committed? |
|---|---|---|
| `inst/default-config.yaml` | Shared application defaults, including host and port | Yes |
| `config-template.yaml` at the root | Template for installation paths and named profiles | Yes |
| `config.yaml` at the root | Your completed installation settings | No |

Create your local file once, then edit it:

```sh
cp config-template.yaml config.yaml
```

The user template contains the settings that vary between installations:

```yaml
default:
  openvqa_dir: null

development:
  openvqa_dir: "../OpenVQA"

production:
  openvqa_dir: "/opt/OpenVQA"
```

Replace the example paths with your own; prefer absolute paths when configuring
OpenVQA. Leave `openvqa_dir: null` while developing the interface without OpenVQA.
Keep the template and copy it rather than renaming it.

At startup, the dashboard loads `inst/default-config.yaml`, resolves the selected
profile from `config.yaml`, then merges the user values into the shared defaults.
User values take precedence, including explicit null values. Omitted settings
retain their shared defaults. For example, `shiny: {port: 8001}` in a user profile
changes the port while retaining the shared host.

`default` is the base user profile; other user profiles inherit from it. Select
a profile with `R_CONFIG_ACTIVE`:

```sh
R_CONFIG_ACTIVE=development Rscript dev/run_dev.R
```

Or in an R console:

```r
Sys.setenv(R_CONFIG_ACTIVE = "development")
source("dev/run_dev.R")
```

The shell example sets the environment variable for that command; the R example
sets it for the current R session. Without profile selection, the app uses the
`default` profile and serves `http://127.0.0.1:8000`.

`config.yaml` is excluded from Git and R package builds. Ordinary Git updates
leave it untouched, and the app never rewrites it. Updated shared defaults apply
to settings that your local file does not override. Restart after editing either
file. If a port is occupied, stop the other app or override the port in your
local settings. A null port requests Shiny's automatic port.

`run_app()` requires `config.yaml` in the working directory and produces setup
instructions if it is missing. To select a different file, including when using
an installed package, pass its path explicitly:

```r
app <- openvqadashboard::run_app(config_file = "/absolute/path/to/config.yaml")
print(app)
```

Installed packages bundle the shared defaults. Create a local settings file
using the user example above or the root template from the source repository.
Explicit launch options, such as `run_app(options = list(port = 8001))`, take
precedence over the user file and shared defaults.

OpenVQA remains a separate installation with its own `rv sync`. Its directory
is stored in the app's golem options for the analysis runner; it is not yet
checked or executed. Scientific analysis settings remain in OpenVQA's
`params.yaml` files. For a hosted dashboard, the server administrator supplies
the configuration; browser users do not need their own OpenVQA installation.

## Tests

Tests use testthat. From the repository root, run:

```sh
Rscript -e 'testthat::test_local()'
```

The configuration tests use temporary files and leave your local settings
untouched.

GitHub Actions runs this suite on Ubuntu 24.04, macOS 26 and Windows 2025 for
pull requests, pushes to `main` and manual runs. The reusable setup action in
`.github/actions/setup-r-environment/action.yml` installs R 4.5.2 and rv 0.22.2,
then runs `rv sync --locked` against the root project. Commit dependency and
lockfile changes together; CI fails if synchronization would change the lock.

Package libraries are cached separately by runner image, OS, architecture,
tool versions and the hashes of `rproject.toml` and `rv.lock`. Each job starts
with its own runner and still synchronizes dependencies after restoring a
cache. The repository's `.Rprofile` activates the root rv library for the R
test step; CI checks that this is R's first library before running the suite.
Tests load the package from source, so CI needs neither a local
`config.yaml` nor an OpenVQA installation.

## Where to develop

- `R/app_ui.R`: page layout, controls and result panels.
- `R/app_server.R`: reactive logic connecting controls to OpenVQA functions.
- `R/app_config.R`: configuration loading, merging and validation.
- `R/run_app.R`: exported application launcher.
- `dev/run_dev.R`: local development entry point.
- `rproject.toml` and `rv.lock`: project dependencies managed by rv.
- `DESCRIPTION`, `NAMESPACE` and `man/`: R package metadata and documentation.

Keep scientific calculations in OpenVQA and run it in a separate R process
when integrating the first analysis. Introduce Shiny modules when sections
need their own state or reuse, and targets when a concrete workflow needs it.

When adding a dependency, use `rv add <package>` and declare package runtime
dependencies in `DESCRIPTION` too. Before distributing the package, complete
the maintainer name/email and agreed license in `DESCRIPTION`.
