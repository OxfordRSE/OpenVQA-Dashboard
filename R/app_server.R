app_server <- function(input, output, session) {
  # Keep each session's catalogue stable so its IDs cannot shift during selection.
  backend <- shiny::reactive(local_backend_status(golem::get_golem_options("openvqa_dir")))
  catalogue <- shiny::reactive(discover_projects(golem::get_golem_options("projects_dir")))
  output$backend_status <- shiny::renderUI({
    status <- backend()
    connected <- status$status == "ok"
    # Pair the decorative dot with text so colour is not the only indication of status.
    shiny::tags$div(
      role = "status",
      shiny::tags$span(
        title = status$message,
        if (connected) {
          paste0("OpenVQA: v", status$version, " - connected")
        } else {
          "OpenVQA: unavailable - disconnected"
        },
        " ",
        shiny::tags$span(
          class = if (connected) "text-success" else "text-danger",
          `aria-hidden` = "true", "\u25cf"
        )
      ),
      if (!connected) shiny::p(status$message, class = "small mt-1 mb-0")
    )
  })
  output$projects_status <- shiny::renderText(catalogue()$message)
  output$projects_source <- shiny::renderText({
    path <- golem::get_golem_options("projects_dir")
    if (is.null(path)) "Not configured" else path
  })
  # Keep the grid independent of selection so clicking does not replace the focused button.
  output$project_cards <- shiny::renderUI(project_cards(catalogue()$projects))

  selected_project_id <- shiny::reactiveVal(NULL)
  # Register only catalogue-owned button IDs; observers are cleaned up with the session.
  shiny::observe({
    lapply(names(catalogue()$projects), function(id) {
      shiny::observeEvent(input[[id]], {
        selected_project_id(id)
      })
    })
  })

  selected_project <- shiny::reactive({
    id <- selected_project_id()
    # Depend on the click counter to recheck disk changes even when the same card is clicked again.
    if (!is.null(id)) {
      input[[id]]
    }
    resolve_catalogue_selection(catalogue(), id)
  })
  selected_assessment <- shiny::reactive({
    if (is.null(input$assessment_id)) {
      return(NULL)
    }
    resolve_catalogue_selection(catalogue(), selected_project_id(), input$assessment_id)
  })
  output$selection_status <- shiny::renderText({
    if (catalogue()$status != "ok") {
      return(NULL)
    }
    tryCatch(
      {
        project <- selected_project()
        if (is.null(project)) "Select a project." else paste("Selected project:", project$name)
      },
      error = function(error) conditionMessage(error)
    )
  })
  invisible(list(project = selected_project, assessment = selected_assessment))
}
