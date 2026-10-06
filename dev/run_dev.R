# Run from the repository root; rv activates through .Rprofile.
source("R/app_ui.R", local = TRUE)
source("R/app_server.R", local = TRUE)
source("R/run_app.R", local = TRUE)
print(run_app())
