testthat::test_that("backend checks read the version without evaluating backend code", {
  root <- local_backend()
  before <- lapply(list.files(root, full.names = TRUE), readLines)
  result <- local_backend_status(root)
  testthat::expect_equal(result$status, "ok")
  testthat::expect_equal(result$version, "0.1.0")
  testthat::expect_match(result$message, "analysis readiness has not been checked", fixed = TRUE)
  testthat::expect_equal(lapply(list.files(root, full.names = TRUE), readLines), before)
})

testthat::test_that("backend setup and failures are actionable", {
  testthat::expect_equal(local_backend_status(NULL)$status, "setup")
  testthat::expect_match(local_backend_status(NULL)$message, "openvqa_dir")
  root <- local_backend()
  testthat::expect_equal(local_backend_status(file.path(root, "missing"))$status, "unavailable")
  for (file in c("validate.R", "analyse.R", "VERSION")) {
    source <- file.path(root, file)
    file.rename(source, paste0(source, ".backup"))
    result <- local_backend_status(root)
    testthat::expect_equal(result$status, "unavailable")
    testthat::expect_match(result$message, file, fixed = TRUE)
    file.rename(paste0(source, ".backup"), source)
  }
  for (version in list(character(), "  ", c("0.1.0", "extra"))) {
    writeLines(version, file.path(root, "VERSION"))
    testthat::expect_match(local_backend_status(root)$message, "VERSION must contain")
  }
  unlink(file.path(root, "validate.R"))
  dir.create(file.path(root, "validate.R"))
  testthat::expect_equal(local_backend_status(root)$status, "unavailable")
})

testthat::test_that("discovery lists only immediate matching projects and assessments in order", {
  root <- local_project_collection()
  before <- list.files(root, recursive = TRUE, all.files = TRUE, include.dirs = TRUE)
  contents <- lapply(list.files(root, recursive = TRUE, full.names = TRUE), readLines)
  result <- discover_projects(root)
  testthat::expect_equal(result$status, "ok")
  testthat::expect_equal(
    vapply(result$projects, `[[`, "", "name"),
    c(project_1 = "a_project", project_2 = "z_project")
  )
  testthat::expect_equal(
    vapply(result$projects$project_1$assessments, `[[`, "", "name"),
    c(assessment_1 = "earlier", assessment_2 = "same")
  )
  testthat::expect_length(result$projects$project_2$assessments, 1L)
  testthat::expect_false(dir.exists(file.path(root, "a_project", "earlier", "results")))
  testthat::expect_equal(
    list.files(root, recursive = TRUE, all.files = TRUE, include.dirs = TRUE), before
  )
  testthat::expect_equal(
    lapply(list.files(root, recursive = TRUE, full.names = TRUE), readLines), contents
  )
})

testthat::test_that("setup, unavailable paths and empty collections have distinct states", {
  root <- withr::local_tempdir()
  file <- file.path(root, "file")
  writeLines("not a directory", file)
  testthat::expect_equal(discover_projects(NULL)$status, "setup")
  testthat::expect_match(discover_projects(NULL)$message, "projects_dir")
  testthat::expect_equal(discover_projects(root)$status, "empty")
  for (path in list(file.path(root, "missing"), file, "", NA_character_, FALSE, c(root, root))) {
    result <- discover_projects(path)
    testthat::expect_equal(result$status, "unavailable")
    testthat::expect_length(result$projects, 0L)
  }
})

testthat::test_that("matching hidden and backup folders are included", {
  root <- withr::local_tempdir()
  for (name in c(".hidden", "project-backup")) {
    dir.create(file.path(root, name, ".assessment", "inputs"), recursive = TRUE)
  }
  result <- discover_projects(root)
  testthat::expect_equal(result$status, "ok")
  testthat::expect_equal(
    vapply(result$projects, `[[`, "", "name"),
    c(project_1 = ".hidden", project_2 = "project-backup")
  )
})

testthat::test_that("unreadable directories and backend files are reported as unavailable", {
  testthat::skip_on_os("windows")
  root <- local_project_collection()
  backend <- local_backend()
  blocked <- file.path(root, "a_project", "earlier", "inputs")
  version <- file.path(backend, "VERSION")
  # Restore access before temporary-directory cleanup, even if an expectation fails.
  withr::defer(Sys.chmod(c(blocked, version), "0700"))
  Sys.chmod(c(blocked, version), "0000")
  testthat::skip_if(file.access(blocked, 4L) == 0L, "User can bypass filesystem permissions")
  testthat::expect_equal(discover_projects(root)$status, "unavailable")
  testthat::expect_equal(local_backend_status(backend)$status, "unavailable")
  Sys.chmod(blocked, "0700")
  withr::defer(Sys.chmod(root, "0700"))
  Sys.chmod(root, "0000")
  testthat::expect_equal(discover_projects(root)$status, "unavailable")
})

testthat::test_that("containment requires a directory boundary and permits links within the root", {
  root <- local_project_collection()
  canonical <- normalizePath(root, winslash = "/")
  testthat::expect_false(path_in_collection(paste0(canonical, "-outside/project"), canonical))
  testthat::expect_false(path_in_collection(canonical, canonical))
  testthat::expect_true(path_in_collection(file.path(canonical, "project"), canonical))
  local_directory_link(file.path(root, "a_project"), file.path(root, "linked_project"))
  catalogue <- discover_projects(root)
  testthat::expect_equal(catalogue$status, "ok")
  testthat::expect_length(catalogue$projects, 3L)
  testthat::expect_equal(resolve_catalogue_selection(catalogue, "project_2")$name, "linked_project")
})

testthat::test_that("escaping symlinks at all discovery levels are excluded", {
  root <- local_project_collection()
  outside <- local_project_collection()
  local_directory_link(file.path(outside, "a_project"), file.path(root, "escape_project"))
  local_directory_link(
    file.path(outside, "a_project", "same"),
    file.path(root, "a_project", "escape_assessment")
  )
  inputs_parent <- file.path(root, "a_project", "escape_inputs")
  dir.create(inputs_parent)
  local_directory_link(
    file.path(outside, "a_project", "same", "inputs"),
    file.path(inputs_parent, "inputs")
  )
  result <- discover_projects(root)
  testthat::expect_equal(result$status, "ok")
  testthat::expect_length(result$projects, 2L)
  testthat::expect_length(result$projects$project_1$assessments, 2L)
})

testthat::test_that("selection accepts only IDs in the discovered catalogue", {
  root <- local_project_collection()
  catalogue <- discover_projects(root)
  testthat::expect_null(resolve_catalogue_selection(catalogue, NULL))
  testthat::expect_equal(resolve_catalogue_selection(catalogue, "project_1")$name, "a_project")
  first <- resolve_catalogue_selection(catalogue, "project_1", "assessment_2")
  second <- resolve_catalogue_selection(catalogue, "project_2", "assessment_1")
  testthat::expect_equal(first$name, second$name)
  testthat::expect_false(identical(first$path, second$path))
  for (id in list(
    "../a_project", "project_1/../project_2", "a_project", root,
    "project_99", "", NA_character_, 1, c("project_1", "project_2")
  )) {
    testthat::expect_error(resolve_catalogue_selection(catalogue, id), "Invalid project selection")
  }
  for (id in c("../same", "assessment_3", "same", first$path)) {
    testthat::expect_error(
      resolve_catalogue_selection(catalogue, "project_1", id),
      "Invalid assessment selection"
    )
  }
  testthat::expect_error(
    resolve_catalogue_selection(discover_projects(NULL), "project_1"),
    "Invalid project selection"
  )
})

testthat::test_that("selections are rechecked when paths disappear or become escaping symlinks", {
  root <- local_project_collection()
  outside <- local_project_collection()
  catalogue <- discover_projects(root)
  assessment <- catalogue$projects$project_1$assessments$assessment_1$path
  # Replace a previously safe entry to exercise selection checks beyond the initial scan.
  unlink(assessment, recursive = TRUE)
  testthat::expect_error(
    resolve_catalogue_selection(catalogue, "project_1", "assessment_1"),
    "missing or unreadable"
  )
  local_directory_link(file.path(outside, "a_project", "same"), assessment)
  testthat::expect_error(
    resolve_catalogue_selection(catalogue, "project_1", "assessment_1"),
    "outside the collection or has changed"
  )
  inputs <- file.path(catalogue$projects$project_2$assessments$assessment_1$path, "inputs")
  unlink(inputs, recursive = TRUE)
  local_directory_link(file.path(outside, "z_project", "same", "inputs"), inputs)
  testthat::expect_error(
    resolve_catalogue_selection(catalogue, "project_2", "assessment_1"),
    "inputs are outside"
  )
})

testthat::test_that("selected project paths cannot be replaced with escaping links", {
  root <- local_project_collection()
  outside <- local_project_collection()
  catalogue <- discover_projects(root)
  project <- catalogue$projects$project_1$path
  unlink(project, recursive = TRUE)
  testthat::expect_error(
    resolve_catalogue_selection(catalogue, "project_1"), "missing or unreadable"
  )
  local_directory_link(file.path(outside, "a_project"), project)
  testthat::expect_error(
    resolve_catalogue_selection(catalogue, "project_1"),
    "outside the collection or has changed"
  )
})
