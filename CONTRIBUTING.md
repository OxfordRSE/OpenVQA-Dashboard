# Contributing to OpenVQA Dashboard

## Development setup

From the repository root, run `rv sync` and create `config.yaml` from
`config-template.yaml` if it does not already exist. Configure your local paths
and theme using the [configuration guide](inst/configuration.md).

Launch with `Rscript dev/run_dev.R`, or use `source("dev/run_dev.R")` from an R
console in the repository root. The script sources the application directly;
package installation and documentation generation are not required for this
development workflow.

Stop every server you start after testing, including alternate-port/theme
previews, and verify that its port is released. Use the configured local theme
for normal previews and preserve the user's `config.yaml`.

## Project structure

| Location | Responsibility |
| --- | --- |
| `R/app_ui.R` | Layout and controls |
| `R/app_server.R` | Session state and navigation |
| `R/app_config.R` | Configuration loading, merging and validation |
| `R/local_projects.R` | Read-only backend checks, discovery and selection validation |
| `R/run_app.R` | Exported application launcher |
| `dev/run_dev.R` | Source development entry point |
| `tests/testthat/` | Automated tests and temporary fixtures |
| `rproject.toml`, `rv.lock` | Dependencies managed by rv |
| `DESCRIPTION`, `NAMESPACE`, `man/` | R package metadata and help |

Keep scientific calculations in OpenVQA, using a separate R process when
integrating analysis execution. Introduce Shiny modules when a section needs
independent state or reuse. Repository coding conventions are in
[AGENTS.md](AGENTS.md).

## Dependencies and package documentation

Add a dependency with `rv add <package>` and declare it in `DESCRIPTION` as well:
runtime packages belong in `Imports`, test/development packages in `Suggests`.
Commit dependency configuration and lock-file changes together.

Keep exported function documentation in `man/` consistent with the roxygen
comments in `R/`. Before distributing the package, complete maintainer
name/email and license metadata in `DESCRIPTION`.

The configuration guide under `inst/` ships with installed packages. Contributor
instructions, planning files, local settings, themes and mockups are source-only;
their package exclusions are maintained in [.Rbuildignore](.Rbuildignore).

## Formatting and lint

Use styler's default tidyverse style and lintr's default checks with a
100-character line limit. Lintr's indentation check is disabled so styler owns
indentation. Package calls remain namespace-qualified as described in AGENTS.md.

After `rv sync`, install the
[pre-commit framework](https://pre-commit.com/#installation) if needed, then
enable the hook once per clone:

```sh
pre-commit install
```

The hooks format and lint staged `.R`, `.r` and `.Rprofile` files using the
project environment. Generated `rv/` files are excluded. If formatting changes
files, review and stage them before retrying the commit. Fix lint findings
manually. Run the hooks over all tracked R files with:

```sh
pre-commit run --all-files
```

Configuration lives in [.pre-commit-config.yaml](.pre-commit-config.yaml) and
[.lintr](.lintr). Formatting and lint do not replace functional tests.

## Tests and visual checks

Run the testthat suite from the repository root:

```sh
Rscript -e 'testthat::test_local()'
```

Tests use temporary fixtures and leave local configuration and scientific data
untouched. They must run without an OpenVQA installation or private data.
Keep scientific correctness tests in OpenVQA; test the dashboard's validation
and integration boundaries here.

For visible UI changes, inspect the affected controls and outputs in both the
neutral and configured local colourways. Prioritise laptop and PC layouts,
check keyboard navigation and record screenshots. Stop test servers afterwards.

## Continuous integration

[The workflow](.github/workflows/tests.yml) runs tests on Ubuntu, macOS and
Windows, with a separate Ubuntu style/lint job. It runs for pull requests,
pushes to `main` and manual requests.

[The reusable setup action](.github/actions/setup-r-environment/action.yml)
defines tool versions, restores the environment-specific library cache and runs
`rv sync --locked`. CI fails if synchronization would change the lock. The
test job checks that `.Rprofile` activated the project library before loading
the package from source. CI needs neither `config.yaml` nor OpenVQA.

## Changes and planning

Use concise imperative commit subjects. Describe the behaviour changed and its
validation in pull requests, include screenshots for visible changes and link
an issue when applicable.

[plan.md](plan.md) is the active implementation roadmap.
[Integration decisions](dev/planning/integration-decisions.md) explain the design
rationale and unresolved questions; keep phase status and acceptance criteria
in the plan.
