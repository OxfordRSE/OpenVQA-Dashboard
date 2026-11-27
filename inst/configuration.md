# Dashboard configuration

Configure the dashboard's local settings, OpenVQA installation and project
collection before launching. The dashboard currently browses projects and
assessments without modifying their inputs or running scientific operations.

## Configuration files

| File | Purpose | Committed? |
| --- | --- | --- |
| `inst/default-config.yaml` | Shared application defaults, including host and port | Yes |
| Root `config-template.yaml` | Template for installation paths and named profiles | Yes |
| Root `config.yaml` | Your installation settings | No |

From the source repository root, create your local file once:

```sh
cp config-template.yaml config.yaml
```

Keep the template rather than renaming it. On later launches, use your existing
`config.yaml`. The app never rewrites it, and ordinary Git updates leave it
untouched. Restart the app after editing settings.

The template contains these installation settings:

```yaml
default:
  openvqa_dir: null
  projects_dir: null
  theme_file: "themes/default.yml"

development:
  openvqa_dir: "../OpenVQA"
  projects_dir: "../OpenVQA/data"

production:
  openvqa_dir: "/opt/OpenVQA"
  projects_dir: "/srv/openvqa-projects"
```

Replace the examples with your own paths. For a hosted dashboard, the server
administrator supplies the configuration.

## Installation paths and themes

`openvqa_dir` identifies the separately installed OpenVQA backend code.
`projects_dir` identifies the collection of project folders. They can live
independently. Leave either setting null to see setup instructions while
developing the interface. OpenVQA has its own dependencies and `rv sync`.

Relative installation paths resolve against the selected settings file's
directory, including when that file is outside the repository. For example,
`../OpenVQA/data` in the dashboard root's `config.yaml` selects the neighbouring
checkout's data collection. Absolute paths and `~` are supported. The dashboard
does not change the process working directory to resolve paths.

`theme_file` selects a readable brand YAML file with any filename. The source
template selects the neutral `themes/default.yml`; choose your local colourway
in `config.yaml`. Theme paths use the same resolution rule as installation
paths. Set `theme_file: null` to disable branding and use Bootstrap defaults.
The source checkout's `themes/README.md` explains customisation.

Organisation-specific themes and local configuration belong in ignored files.
The source `themes/` directory is excluded from package builds: installed-package
users must supply their own theme file or set `theme_file: null`.

## Profiles and precedence

The app loads shared defaults, resolves the selected user profile, then applies
user values. User values take precedence, including explicit nulls. Omitted
settings retain their shared defaults. For example, `shiny: {port: 8001}` in
a user profile changes the port while retaining the shared host.

`default` is the base user profile; other profiles inherit from it. Select one
with `R_CONFIG_ACTIVE`:

```sh
R_CONFIG_ACTIVE=development Rscript dev/run_dev.R
```

Or in an R console started at the repository root:

```r
Sys.setenv(R_CONFIG_ACTIVE = "development")
source("dev/run_dev.R")
```

The shell example selects the profile for that command; the R example selects
it for the current R session. Without selection, the app uses the `default`
profile. The shared host and port are `127.0.0.1:8000` unless overridden.

## Launching from R and installed packages

The development script sources the app directly; it does not require package
installation or documentation generation. Open the local URL printed by Shiny
and stop the server with Ctrl+C.

The exported `run_app()` requires a user configuration file, defaulting to
`config.yaml` in the working directory. Missing configuration produces an error
with setup instructions. To use another file with an installed package:

```r
app <- openvqadashboard::run_app(config_file = "/absolute/path/to/config.yaml")
print(app)
```

Installed packages include shared defaults and this guide. Create your own
settings file using the YAML example above, adapting the theme path as described
earlier. The guide is available at:

```r
system.file("configuration.md", package = "openvqadashboard")
```

Explicit Shiny launch options, such as
`openvqadashboard::run_app(options = list(port = 8001))`, override the merged
Shiny settings. Installation paths and theme selection remain in the user file.
See `?openvqadashboard::run_app` for the launcher arguments.

## Project collection

The backend check requires readable `validate.R`, `analyse.R` and `VERSION`
files. The displayed version comes from `VERSION`. This establishes filesystem
connectivity; it does not load backend code or check analysis dependencies.

Project discovery expects:

```text
projects_dir/
  project_name/
    params.yaml          # Optional scientific settings
    assessment_name/
      inputs/            # Required for discovery; files are not validated
```

Only immediate project folders containing at least one immediate assessment
with an `inputs/` directory qualify. Results, figures and logs are optional.
Discovery does not search deeper. Folder names supply the labels, sorted
deterministically, including structurally matching hidden and backup folders.
Symlinks escaping the collection are excluded; server selections are checked
against the catalogue and current filesystem before use.

Open a project card by clicking it or using Tab followed by Enter or Space.
Choose an assessment from the sidebar's native radio controls. Back to projects
returns to the grid; switching projects clears the assessment selection.
Selections belong to the current browser session. The sidebar also shows the
collection path, software versions and backend connectivity.

An inputs directory being found does not mean that its data passed validation.
The browser does not write to project data or run analyses. Scientific settings
remain in OpenVQA's `params.yaml`.

## Troubleshooting

- **Missing configuration:** create `config.yaml` once or pass its path to
  `run_app(config_file = ...)`.
- **Setup instructions:** check that installation paths are set in the active
  profile. Named profiles require `R_CONFIG_ACTIVE` selection.
- **Unavailable backend or collection:** check directory paths, read/traversal
  permissions and the required backend files. Unreadable directories produce
  an unavailable status rather than an empty result.
- **Empty collection:** compare the directory layout with the example above.
  A project needs at least one immediate assessment with `inputs/`.
- **Folders changed while browsing:** reload the browser to rescan. Restart the
  app after configuration changes.
- **Port occupied:** stop the other server or set, for example,
  `shiny: {port: 8001}` in your user profile. An explicit null port requests
  Shiny's automatic port.
- **Unexpected theme:** check `theme_file` in the active profile and the URL's
  port. Restart after changing the theme. Unreadable files fail configuration
  checks; invalid brand YAML is reported when the interface renders.
