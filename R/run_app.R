run_app <- function(options = list(), config_file = "config.yaml") {
  settings <- read_app_config(config_file = config_file, options = options)

  golem::with_golem_options(
    app = shiny::shinyApp(
      ui = app_ui,
      server = app_server,
      options = settings$shiny
    ),
    golem_opts = list(openvqa_dir = settings$openvqa_dir)
  )
}
