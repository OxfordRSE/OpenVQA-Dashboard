# OpenVQA Dashboard

A Shiny interface for browsing local OpenVQA projects and assessments, built
with bslib and a golem launcher. The R package is `openvqadashboard`.

The current dashboard is read-only: it discovers projects and assessments and
checks backend connectivity. Validation runs, analyses and result exploration
are planned; they are not yet available from the interface.

## Run locally

For first-time setup, from the repository root:

```sh
rv sync
cp config-template.yaml config.yaml
# Edit config.yaml with your installation paths and theme.
Rscript dev/run_dev.R
```

Set `openvqa_dir` to your separately installed OpenVQA checkout and `projects_dir`
to your project collection. Select your colourway with `theme_file`. Relative
paths resolve against the configuration file's directory.

Copy the template only once. For later launches, keep your existing `config.yaml`
and run `Rscript dev/run_dev.R`. If you configured a named profile, select it:

```sh
R_CONFIG_ACTIVE=development Rscript dev/run_dev.R
```

Open the URL printed by Shiny, normally `http://127.0.0.1:8000`. Stop the server with Ctrl+C.

## Guides

- [Configuration](inst/configuration.md): installation paths, profiles, project
  layout, installed-package usage and troubleshooting.
- [Themes](themes/README.md): custom colourways and local branding.
- [Contributing](CONTRIBUTING.md): development setup, tests, formatting and CI.
