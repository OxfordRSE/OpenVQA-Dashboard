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
- `pre-commit install`: enable the local Git hook after installing pre-commit
  and running `rv sync`.
- `pre-commit run --all-files`: format and lint maintained R files.

Declare runtime dependencies in `DESCRIPTION` as well as rv configuration.
Complete maintainer and license metadata before distributing the package.

## Coding Style & Naming Conventions

Use two-space indentation, `<-` for assignment, and `snake_case` for functions
and files. Keep scientific computation in OpenVQA and use the dashboard to
collect inputs, invoke analyses, and display results. Add modules when a
section needs independent state or reuse. Use styler's default tidyverse style
and lintr's checks with a 100-character line limit through pre-commit. Styler
owns indentation; lintr's indentation check is disabled to avoid conflicting
rules. Generated files under `rv/` are excluded.

### Branding and visual styling

- Use the configured brand YAML through `bslib::bs_theme(brand = ...)` as the
  source of colours, fonts and other brand settings. Keep organisation-specific
  palettes in ignored local theme files, never in application code.
- Use bslib/Shiny component arguments, supported `bs_theme()`/`bs_theme_update()`
  Sass settings and Bootstrap utility classes for visual styling. Let the
  framework derive subtle colours and contrasting foregrounds from the theme.
- Do not add custom CSS rules, inline colour styles, `bs_add_rules()` overrides
  or manually set CSS custom properties for branding when the framework offers
  a supported setting or utility. Inspect the installed API before adding CSS.
- Reserve custom CSS for layout or interactions the framework cannot express;
  explain why it is needed. Preserve keyboard focus and readable contrast, and
  verify changes with both the neutral and local colourways.

### Comments and function documentation

- Add concise comments to new or changed code where the reason for a decision
  is not obvious, especially in longer functions and files. Explain why a
  constraint, validation check or unusual approach is needed, rather than
  restating the code. Keep comments accurate when behaviour changes.
- Add roxygen-style (`#'`) function docstrings where they help a caller or
  maintainer understand the contract. Describe purpose, arguments, return
  values and important side effects or failure behaviour for exported functions
  and non-trivial internal helpers. Use `@noRd` for internal documentation;
  keep exported documentation in `man/` consistent. Trivial helpers and named
  test cases do not need boilerplate documentation.

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
