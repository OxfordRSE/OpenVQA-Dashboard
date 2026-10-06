app_ui <- function(request) {
  bslib::page_sidebar(
    title = "OpenVQA",
    sidebar = bslib::sidebar(
      title = "Analysis",
      shiny::p("Data selection and analysis settings will go here.")
    ),
    bslib::card(
      bslib::card_header("Welcome to OpenVQA"),
      shiny::p("Use this dashboard to configure analyses and explore results.")
    )
  )
}
