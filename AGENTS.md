# Repository Guidelines

## Project Structure & Module Organization

This repository contains the `openvqadashboard` R package: a Shiny interface
with bslib layouts and a golem launcher. Edit `R/app_ui.R` for the interface,
`R/app_server.R` for reactive logic, and `R/run_app.R` for application startup.
`dev/run_dev.R` launches the source files during development. Package metadata
lives in `DESCRIPTION` and `NAMESPACE`; exported function documentation lives
in `man/`. No tests or custom assets exist yet.

## Development Commands

- `rv sync`: install dependencies from `rv.lock` into the project library.
- `Rscript dev/run_dev.R`: launch the dashboard from the repository root.
- `source("dev/run_dev.R")`: launch from an R console in this directory.
- `rv add <package>`: add a dependency and update the rv lock file.

Declare runtime dependencies in `DESCRIPTION` as well as rv configuration.
Complete maintainer and license metadata before distributing the package.

## Coding Style & Naming Conventions

Use two-space indentation, `<-` for assignment, and `snake_case` for functions
and files. Qualify dependency calls, for example `bslib::card()` and
`shiny::renderPlot()`. Keep scientific computation in OpenVQA and use the
dashboard to collect inputs, invoke analyses, and display results. Add modules
when a section needs independent state or reuse. No formatter is configured.

## Testing Guidelines

No testing framework or coverage threshold is configured. For UI changes,
launch the app and inspect the affected controls and outputs. When analysis
integration is added, test validation and error handling with small example
inputs; keep scientific correctness tests in OpenVQA.

## Commit & Pull Request Guidelines

There is no established commit history. Use concise imperative subjects,
such as `Add analysis configuration controls`. Describe the change and its
validation in pull requests; include screenshots for visible UI changes and
link an issue when applicable. Commit dependency configuration and lock-file
changes together.
