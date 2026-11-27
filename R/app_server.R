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
  selected_assessment_id <- shiny::reactiveVal(NULL)
  # Register only catalogue-owned button IDs; observers are cleaned up with the session.
  shiny::observe({
    lapply(names(catalogue()$projects), function(id) {
      shiny::observeEvent(input[[id]], {
        selected_assessment_id(NULL)
        selected_project_id(id)
      })
      # Scope the input to its project so delayed events cannot select another project's assessment.
      shiny::observeEvent(input[[paste0(id, "_assessment")]],
        {
          if (identical(selected_project_id(), id)) {
            selected_assessment_id(input[[paste0(id, "_assessment")]])
          }
        },
        ignoreNULL = FALSE
      )
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
    if (is.null(selected_assessment_id())) {
      return(NULL)
    }
    resolve_catalogue_selection(catalogue(), selected_project_id(), selected_assessment_id())
  })
  shiny::observeEvent(input$back_to_projects, {
    selected_assessment_id(NULL)
    selected_project_id(NULL)
  })
  shiny::observeEvent(input$project_overview, {
    shiny::req(selected_project_id())
    selected_assessment_id(NULL)
    # Clear the browser's radio selection as well as the server's assessment state.
    shiny::updateRadioButtons(session, paste0(selected_project_id(), "_assessment"),
      selected = character(0)
    )
  })
  shiny::observe({
    bslib::nav_select("project_view",
      selected = if (is.null(selected_project_id())) "projects" else "assessments"
    )
  })
  output$project_navigation <- shiny::renderUI({
    if (is.null(selected_project_id())) {
      return(NULL)
    }
    shiny::tagList(
      shiny::actionButton("back_to_projects", "Back to projects", class = "btn-primary mb-3"),
      tryCatch(
        {
          project <- selected_project()
          shiny::tagList(
            shiny::tags$h2(project$name, class = "h5 text-break"),
            shiny::actionButton("project_overview", "Project overview",
              class = "btn-outline-primary mb-3"
            ),
            shiny::tags$div(
              class = "text-break",
              shiny::radioButtons(
                paste0(selected_project_id(), "_assessment"), "Assessments",
                choices = stats::setNames(names(project$assessments), vapply(
                  project$assessments, function(assessment) assessment$name, character(1)
                )),
                selected = character(0)
              )
            )
          )
        },
        error = function(error) shiny::p(conditionMessage(error))
      )
    )
  })
  output$assessment_title <- shiny::renderText({
    tryCatch(
      {
        project <- selected_project()
        if (is.null(project)) {
          return("Assessments")
        }
        assessment <- selected_assessment()
        if (is.null(assessment)) project$name else paste(project$name, assessment$name, sep = " - ")
      },
      error = function(error) "Assessment unavailable"
    )
  })
  output$assessment_status <- shiny::renderText({
    tryCatch(
      {
        if (is.null(selected_project())) {
          return("Select a project.")
        }
        assessment <- selected_assessment()
        if (is.null(assessment)) {
          "Select an assessment from the sidebar."
        } else {
          "Inputs directory found. Data inspection, validation and analysis are not available yet."
        }
      },
      error = function(error) paste(conditionMessage(error), "Return to projects and reload.")
    )
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
