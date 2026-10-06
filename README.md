# OpenVQA Dashboard

A minimal Shiny application using bslib for layout and golem for the app
launcher. The R package name is `openvqadashboard`.

## Run locally

From the repository root:

```sh
rv sync
Rscript dev/run_dev.R
```

Open the local URL printed by Shiny. Stop the server with Ctrl+C.
In an R console started in this directory, use `source("dev/run_dev.R")`.
The development script sources the app files directly, so no package
installation or documentation generation is needed while developing.

## Where to develop

- `R/app_ui.R`: page layout, controls and result panels.
- `R/app_server.R`: reactive logic connecting controls to OpenVQA functions.
- `R/run_app.R`: exported application launcher.
- `dev/run_dev.R`: local development entry point.
- `rproject.toml` and `rv.lock`: project dependencies managed by rv.
- `DESCRIPTION`, `NAMESPACE` and `man/`: R package metadata and documentation.

Keep scientific calculations in OpenVQA. Add its dependency when integrating
the first analysis. Introduce Shiny modules when sections need their own
state or reuse, and targets when a concrete workflow needs it.

When adding a dependency, use `rv add <package>` and declare package runtime
dependencies in `DESCRIPTION` too. Before distributing the package, complete
the maintainer name/email and agreed license in `DESCRIPTION`.
