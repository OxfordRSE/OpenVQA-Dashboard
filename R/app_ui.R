app_ui <- function(request) {
  bslib::page_sidebar(
    title = "OpenVQA-Dashboard",
    sidebar = bslib::sidebar(
      title = "Analysis",
      shiny::p("Data selection and analysis settings will go here.")
    ),
    bslib::card(
      bslib::card_header("Welcome to OpenVQA-Dashboard"),
      shiny::p("Use this dashboard to configure analyses and explore results."),
      shiny::tags$div(
        role = "status",
        shiny::textOutput("backend_status"),
        shiny::textOutput("projects_status")
      )
    )
  )
}
