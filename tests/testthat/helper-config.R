local_config_file <- function(envir = parent.frame()) {
  path <- withr::local_tempfile(fileext = ".yaml", .local_envir = envir)
  writeLines(c("default:", "  openvqa_dir: null"), path)
  withr::local_envvar(R_CONFIG_ACTIVE = NA, .local_envir = envir)
  path
}
