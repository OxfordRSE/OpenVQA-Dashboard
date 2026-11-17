read_app_config <- function(config_file = "config.yaml", options = list()) {
  if (!file.exists(config_file)) {
    stop(
      "Settings file not found: ", config_file,
      ". Copy config-template.yaml to config.yaml and edit it, ",
      "or supply config_file explicitly.",
      call. = FALSE
    )
  }
  defaults_file <- system.file("default-config.yaml", package = "openvqadashboard")
  if (!nzchar(defaults_file)) {
    defaults_file <- "inst/default-config.yaml"
  }
  defaults <- config::get(config = "default", file = defaults_file, use_parent = FALSE)
  user_settings <- config::get(file = config_file, use_parent = FALSE)
  settings <- utils::modifyList(defaults, user_settings, keep.null = TRUE)
  if (!is.list(settings$shiny)) {
    stop("The settings file must contain a 'shiny' section.", call. = FALSE)
  }
  options <- utils::modifyList(settings$shiny, options, keep.null = TRUE)
  if (!is.character(options$host) || length(options$host) != 1L ||
      is.na(options$host) || !nzchar(options$host)) {
    stop("Shiny host must be a non-empty string.", call. = FALSE)
  }
  if (!is.null(options$port) &&
      (!is.numeric(options$port) || length(options$port) != 1L ||
       is.na(options$port) || options$port < 1 || options$port > 65535 ||
       options$port != floor(options$port))) {
    stop("Shiny port must be an integer from 1 to 65535, or null.", call. = FALSE)
  }
  if (!is.null(settings$openvqa_dir) &&
      (!is.character(settings$openvqa_dir) || length(settings$openvqa_dir) != 1L ||
       is.na(settings$openvqa_dir) || !nzchar(settings$openvqa_dir))) {
    stop("OpenVQA directory must be a non-empty string, or null.", call. = FALSE)
  }

  settings$shiny <- options
  settings
}
