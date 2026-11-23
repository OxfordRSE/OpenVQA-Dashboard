#' Merge application defaults, the selected user profile and launch overrides.
#'
#' @param config_file Required user YAML file; R_CONFIG_ACTIVE selects its profile.
#' @param options Shiny launch options that override the merged shiny section.
#' @return Validated settings with installation paths relative to the config file
#'   expanded to absolute paths. Stops on missing configuration or malformed settings;
#'   directory availability is checked separately so the app can show setup status.
#' @noRd
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
  # Anchor paths to the selected file so launching from another directory is predictable.
  config_dir <- dirname(normalizePath(config_file, winslash = "/", mustWork = TRUE))
  for (field in c("openvqa_dir", "projects_dir")) {
    path <- settings[[field]]
    if (is.null(path)) {
      next
    }
    if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(trimws(path))) {
      stop(field, " must be a non-empty string, or null.", call. = FALSE)
    }
    path <- path.expand(path)
    if (!grepl("^(/|[A-Za-z]:[/\\\\]|\\\\\\\\)", path)) {
      path <- file.path(config_dir, path)
    }
    settings[[field]] <- path
  }

  settings$shiny <- options
  settings
}
