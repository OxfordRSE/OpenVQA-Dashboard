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
  # Bootstrap cannot coordinate a child strip with its parent's hover/focus state.
  theme <- bslib::bs_add_rules(theme, "
    .project-card-control:hover .project-card-meta,
    .project-card-control:focus .project-card-meta {
      @extend .text-bg-primary;
    }
  ")

  bslib::page_sidebar(
    title = "OpenVQA-Dashboard",
    theme = theme,
    sidebar = bslib::sidebar(
      width = 260,
      fillable = TRUE,
      open = list(desktop = "open", mobile = "closed"),
      shiny::uiOutput("project_navigation"),
      shiny::tags$div(
        class = "small text-break",
        shiny::tags$h2("Project source", class = "h6"),
        shiny::p("Local filesystem", class = "mb-0"),
        shiny::textOutput("projects_source")
      ),
      shiny::tags$div(
        class = "mt-auto pt-4 small",
        shiny::tags$h2("Versions", class = "h6 text-body"),
        shiny::p(paste0("R: v", getRversion()), class = "mb-1"),
        shiny::p(paste0("Dashboard: v", dashboard_version), class = "mb-1"),
        shiny::uiOutput("backend_status")
      )
    ),
    # Keep square geometry; Bootstrap handles the action button's hover and focus.
    shiny::tags$head(shiny::tags$style(shiny::HTML("
      .project-card { aspect-ratio: 1 / 1; min-width: 0; min-height: 0; }
      .project-card-control {
        border-radius: inherit;
      }
    "))),
    # Hidden navigation needs fill roles on its containers to retain the full-height workspace.
    bslib::navset_hidden(
      id = "project_view",
      bslib::nav_panel(
        "Projects",
        value = "projects",
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
      ),
      bslib::nav_panel(
        "Assessments",
        value = "assessments",
        bslib::card(
          bslib::card_header(
            class = "bg-primary-subtle text-primary-emphasis",
            shiny::tags$h2(shiny::textOutput("assessment_title", inline = TRUE),
              class = "h5 mb-0 text-break"
            )
          ),
          bslib::card_body(
            fillable = FALSE,
            shiny::tags$div(role = "status", shiny::textOutput("assessment_status"))
          )
        )
      )
    ) |>
      bslib::as_fill_carrier() |>
      bslib::as_fill_carrier(css_selector = ".tab-content") |>
      bslib::as_fill_carrier(css_selector = ".tab-pane")
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
      class = "project-card list-group", fill = FALSE,
      bslib::card_body(
        padding = 0,
        # Put content inside the native button so Bootstrap's hover colours are inherited.
        shiny::actionButton(
          inputId = id,
          label = shiny::tags$span(
            class = "d-flex flex-column",
            shiny::tags$span(
              project$name,
              role = "heading", `aria-level` = "3",
              class = "h5 text-reset text-break p-3 pb-5 mb-0"
            ),
            shiny::tags$span(
              assessments,
              class = paste(
                "project-card-meta bg-secondary-subtle text-secondary-emphasis",
                "position-absolute bottom-0 start-0 fw-normal w-100 px-3 py-1 small"
              )
            )
          ),
          class = paste(
            "project-card-control position-absolute top-0 start-0 w-100 h-100 border-0",
            "list-group-item list-group-item-action d-flex flex-column p-0 text-start",
            "focus-ring focus-ring-primary"
          ),
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
