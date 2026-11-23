#' Run the OpenVQA Dashboard
#'
#' @param options Shiny launch options overriding the settings file.
#' @param config_file Required user YAML settings file. R_CONFIG_ACTIVE selects
#'   a profile; relative installation paths resolve against this file's directory.
#' @return A Shiny application object. Print it to launch the application.
#'   Stops on missing or malformed configuration; backend availability is shown in the UI.
run_app <- function(options = list(), config_file = "config.yaml") {
  settings <- read_app_config(config_file = config_file, options = options)

  golem::with_golem_options(
    app = shiny::shinyApp(
      ui = app_ui,
      server = app_server,
      options = settings$shiny
    ),
    golem_opts = list(
      openvqa_dir = settings$openvqa_dir,
      projects_dir = settings$projects_dir
    )
  )
}
