app_server <- function(input, output, session) {
  # Keep each session's catalogue stable so its IDs cannot shift during selection.
  backend <- shiny::reactive(local_backend_status(golem::get_golem_options("openvqa_dir")))
  catalogue <- shiny::reactive(discover_projects(golem::get_golem_options("projects_dir")))
  output$backend_status <- shiny::renderText(backend()$message)
  output$projects_status <- shiny::renderText(catalogue()$message)

  # These reactives form the server boundary for project and assessment controls.
  selected_project <- shiny::reactive({
    resolve_catalogue_selection(catalogue(), input$project_id)
  })
  selected_assessment <- shiny::reactive({
    if (is.null(input$assessment_id)) {
      return(NULL)
    }
    resolve_catalogue_selection(catalogue(), input$project_id, input$assessment_id)
  })
  invisible(list(project = selected_project, assessment = selected_assessment))
}
