app_ui <- function(request, theme_file = NULL) {
  # The development launcher sources files directly, without installing the package.
  description <- system.file("DESCRIPTION", package = "openvqadashboard")
  if (!nzchar(description)) {
    description <- "DESCRIPTION"
  }
  dashboard_version <- read.dcf(description, fields = "Version")[[1]]

  # Explicit selection prevents an unrelated ancestor brand from affecting the app.
  brand <- if (is.null(theme_file)) FALSE else theme_file
  theme <- bslib::bs_theme(brand = brand)
  colours <- bslib::bs_get_variables(theme, c("primary", "primary-bg-subtle"))
  # Resolve brand colours before setting component defaults; bslib handles contrast.
  theme <- bslib::bs_theme_update(
    theme,
    "navbar-bg" = unname(colours["primary"]),
    "bslib-sidebar-bg" = unname(colours["primary-bg-subtle"])
  )

  bslib::page_sidebar(
    title = "OpenVQA-Dashboard",
    theme = theme,
    sidebar = bslib::sidebar(
      title = "Project source",
      width = 260,
      fillable = TRUE,
      open = list(desktop = "open", mobile = "closed"),
      shiny::p("Local filesystem", class = "mb-0"),
      shiny::tags$div(class = "text-break", shiny::textOutput("projects_source")),
      shiny::tags$div(
        class = "mt-auto pt-4 small",
        shiny::tags$h2("Versions", class = "h6 text-body"),
        shiny::p(paste0("R: v", getRversion()), class = "mb-1"),
        shiny::p(paste0("Dashboard: v", dashboard_version), class = "mb-1"),
        shiny::uiOutput("backend_status")
      )
    ),
    # Keep Bootstrap's theme; custom rules only control card geometry and interaction.
    shiny::tags$head(shiny::tags$style(shiny::HTML("
      .project-card { aspect-ratio: 1 / 1; min-width: 0; min-height: 0; }
      .project-card-control {
        border-radius: inherit; background: transparent;
      }
      .project-card-control:hover { background: rgba(var(--bs-primary-rgb), 0.06); }
      .project-card-control:focus-visible {
        outline: 3px solid var(--bs-primary); outline-offset: -5px;
      }
    "))),
    bslib::card(
      bslib::card_header(
        class = "bg-primary-subtle text-primary-emphasis",
        shiny::tags$h2("Projects", class = "h5 mb-0")
      ),
      bslib::card_body(
        fillable = FALSE,
        shiny::tags$div(role = "status", shiny::textOutput("projects_status")),
        shiny::tags$div(
          role = "status", class = "text-body small mb-3",
          shiny::textOutput("selection_status")
        ),
        shiny::uiOutput("project_cards")
      )
    )
  )
}

#' Render catalogue entries as accessible square cards in a responsive bslib grid.
#'
#' @param projects Server-owned project entries from discover_projects().
#' @return A grid of cards, or NULL for no projects. Action buttons use catalogue
#'   IDs as Shiny input IDs, keeping folder names and paths out of input handling.
#' @noRd
project_cards <- function(projects) {
  if (!length(projects)) {
    return(NULL)
  }
  cards <- lapply(names(projects), function(id) {
    project <- projects[[id]]
    count <- length(project$assessments)
    assessments <- paste(count, if (count == 1L) "assessment" else "assessments")
    bslib::card(
      class = "project-card", fill = FALSE,
      bslib::card_body(
        class = "justify-content-between",
        shiny::tags$h3(project$name, class = "h5 text-break"),
        shiny::p(assessments, class = "text-body-secondary mb-0"),
        # Cover the card while retaining Shiny's native button binding and keyboard behaviour.
        shiny::actionButton(
          inputId = id, label = NULL,
          class = "project-card-control position-absolute top-0 start-0 w-100 h-100 border-0",
          `aria-label` = paste("Select project", project$name, "with", assessments)
        )
      )
    )
  })
  do.call(bslib::layout_column_wrap, c(cards, list(
    width = "220px", heights_equal = "row", fill = FALSE, fillable = FALSE,
    class = "project-grid"
  )))
}
