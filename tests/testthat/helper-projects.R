#' Create a disposable collection with both qualifying projects and discovery decoys.
#'
#' @param envir Test environment whose cleanup removes the fixture.
#' @return The temporary collection root.
#' @noRd
local_project_collection <- function(envir = parent.frame()) {
  root <- withr::local_tempdir(.local_envir = envir)
  # Repeated names catch cross-project mix-ups; the deeper inputs folder must be ignored.
  for (path in c(
    "z_project/same/inputs", "a_project/same/inputs", "a_project/earlier/inputs",
    "unrelated/nested/deep/inputs", "a_project/no_inputs", "empty_project"
  )) {
    dir.create(file.path(root, path), recursive = TRUE)
  }
  writeLines("optional: true", file.path(root, "a_project", "params.yaml"))
  writeLines("unrelated", file.path(root, "notes.txt"))
  root
}

#' Create a disposable backend whose scripts fail if accidentally executed.
#'
#' @param envir Test environment whose cleanup removes the fixture.
#' @return The temporary backend root.
#' @noRd
local_backend <- function(envir = parent.frame()) {
  root <- withr::local_tempdir(.local_envir = envir)
  for (script in c("validate.R", "analyse.R")) {
    writeLines("stop('Backend code must never be loaded')", file.path(root, script))
  }
  writeLines("0.1.0", file.path(root, "VERSION"))
  root
}

local_directory_link <- function(target, link) {
  # Windows runners may lack symlink privileges; skip only the cases that require them.
  created <- suppressWarnings(file.symlink(target, link))
  testthat::skip_if_not(created, "Directory symlinks are unavailable on this platform")
  invisible(link)
}
