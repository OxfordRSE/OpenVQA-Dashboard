app_ui <- function(request) {
  # The development launcher sources files directly, without installing the package.
  description <- system.file("DESCRIPTION", package = "openvqadashboard")
  if (!nzchar(description)) {
    description <- "DESCRIPTION"
  }
  dashboard_version <- read.dcf(description, fields = "Version")[[1]]

  bslib::page_sidebar(
    title = "OpenVQA-Dashboard",
    sidebar = bslib::sidebar(
      title = "Project source",
      width = 260,
      fillable = TRUE,
      open = list(desktop = "open", mobile = "closed"),
      shiny::p("Local filesystem", class = "text-body-secondary mb-0"),
      shiny::tags$div(class = "text-break", shiny::textOutput("projects_source")),
      shiny::tags$div(
        class = "mt-auto pt-4 small text-body-secondary",
        shiny::tags$h2("Versions", class = "h6 text-body"),
        shiny::p(paste0("R: v", getRversion()), class = "mb-1"),
        shiny::p(paste0("Dashboard: v", dashboard_version), class = "mb-1"),
        shiny::uiOutput("backend_status")
      )
    ),
    bslib::card(
      bslib::card_header("Welcome to OpenVQA-Dashboard"),
      shiny::p("Use this dashboard to configure analyses and explore results."),
      shiny::tags$div(
        role = "status",
        shiny::textOutput("projects_status")
      )
    )
  )
}
