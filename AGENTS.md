# Repository Guidelines

## Project Structure & Module Organization

This repository contains the `openvqadashboard` R package: a Shiny interface
with bslib layouts and a golem launcher. Edit `R/app_ui.R` for the interface,
`R/app_server.R` for reactive logic, `R/app_config.R` for configuration loading
and validation, and `R/run_app.R` for application startup.
`dev/run_dev.R` launches the source files during development. Package metadata
lives in `DESCRIPTION` and `NAMESPACE`; exported function documentation lives
in `man/`. Tests live in `tests/testthat/`.

## Development Commands

- `rv sync`: install dependencies from `rv.lock` into the project library.
- Copy the root `config-template.yaml` to the ignored `config.yaml` and edit
  installation settings before launching. Shared defaults live in
  `inst/default-config.yaml`; select user profiles with `R_CONFIG_ACTIVE`.
- `Rscript dev/run_dev.R`: launch the dashboard from the repository root.
- `source("dev/run_dev.R")`: launch from an R console in this directory.
- `rv add <package>`: add a dependency and update the rv lock file.
- `Rscript -e 'testthat::test_local()'`: run the testthat suite from source.

Declare runtime dependencies in `DESCRIPTION` as well as rv configuration.
Complete maintainer and license metadata before distributing the package.

## Coding Style & Naming Conventions

Use two-space indentation, `<-` for assignment, and `snake_case` for functions
and files. Keep scientific computation in OpenVQA and use the dashboard to
collect inputs, invoke analyses, and display results. Add modules when a
section needs independent state or reuse. No formatter is configured.

### Package namespaces

- Use `package::function()` for dependency functions in application code,
  scripts, tests, and examples, including `testthat::test_that()` and
  `testthat::expect_equal()`.
- Base R functions and functions defined in this project may be unqualified.
  Functions from other packages bundled with R still need qualification,
  for example `utils::modifyList()` and `stats::median()`.
- Do not use `library()`, `require()`, or namespace imports to make ordinary
  dependency calls work without a prefix. The standard testthat bootstrap in
  `tests/testthat.R` may attach testthat and this package for test discovery.
- Use exported APIs through `::`; avoid accessing package internals with `:::`.
- Declare dependencies in `DESCRIPTION` (`Imports` for runtime, `Suggests`
  for tests) and rv configuration. Qualification does not declare a dependency.

## Testing Guidelines

Use testthat; no coverage threshold is configured. For UI changes,
launch the app and inspect the affected controls and outputs. When analysis
integration is added, test validation and error handling with small example
inputs; keep scientific correctness tests in OpenVQA.

## Commit & Pull Request Guidelines

There is no established commit history. Use concise imperative subjects,
such as `Add analysis configuration controls`. Describe the change and its
validation in pull requests; include screenshots for visible UI changes and
link an issue when applicable. Commit dependency configuration and lock-file
changes together.
