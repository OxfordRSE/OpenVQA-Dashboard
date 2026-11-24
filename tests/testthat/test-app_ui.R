testthat::test_that("the homepage uses a bslib sidebar with source and version information", {
  html <- as.character(app_ui(NULL))
  testthat::expect_match(html, "bslib-page-sidebar", fixed = TRUE)
  testthat::expect_match(html, "Project source", fixed = TRUE)
  testthat::expect_match(html, 'id="projects_source"', fixed = TRUE)
  testthat::expect_match(html, paste0("R: v", getRversion()), fixed = TRUE)
  testthat::expect_match(html, "Dashboard: v", fixed = TRUE)
  testthat::expect_match(html, 'data-open-mobile="closed"', fixed = TRUE)
  testthat::expect_match(html, "bg-primary-subtle text-primary-emphasis", fixed = TRUE)
})

testthat::test_that("project cards use bslib layout and labelled buttons with catalogue IDs", {
  catalogue <- discover_projects(local_project_collection())
  html <- as.character(project_cards(catalogue$projects))
  testthat::expect_match(html, "bslib-grid", fixed = TRUE)
  testthat::expect_match(html, "project-card", fixed = TRUE)
  testthat::expect_match(html, 'id="project_1"', fixed = TRUE)
  testthat::expect_match(html, 'id="project_2"', fixed = TRUE)
  testthat::expect_match(html, "action-button", fixed = TRUE)
  testthat::expect_match(html, "badge text-bg-secondary fw-normal", fixed = TRUE)
  testthat::expect_match(html, "focus-ring focus-ring-primary", fixed = TRUE)
  testthat::expect_match(html, 'type="button"', fixed = TRUE)
  testthat::expect_match(html, "Select project a_project with 2 assessments", fixed = TRUE)
  testthat::expect_match(html, "Select project z_project with 1 assessment", fixed = TRUE)
  testthat::expect_false(grepl(catalogue$path, html, fixed = TRUE))
  testthat::expect_null(project_cards(list()))
})

testthat::test_that("project names are escaped and never interpolated into click handlers", {
  projects <- list(project_1 = list(
    name = "A very long project name <script>alert('name')</script>",
    assessments = list(assessment_1 = list())
  ))
  html <- as.character(project_cards(projects))
  testthat::expect_match(html, "&lt;script&gt;", fixed = TRUE)
  testthat::expect_false(grepl("<script>alert", html, fixed = TRUE))
  testthat::expect_false(grepl("onclick=", html, fixed = TRUE))
})

testthat::test_that("two projects with two and four assessments produce two project cards", {
  root <- withr::local_tempdir()
  counts <- c("vqa-demo1-min" = 2L, "vqa-demo2-min" = 4L)
  for (project in names(counts)) {
    for (assessment in seq_len(counts[[project]])) {
      dir.create(file.path(root, project, paste0("assessment_", assessment), "inputs"),
        recursive = TRUE
      )
    }
  }
  catalogue <- discover_projects(root)
  html <- as.character(project_cards(catalogue$projects))
  testthat::expect_length(catalogue$projects, 2L)
  testthat::expect_match(html, "Select project vqa-demo1-min with 2 assessments", fixed = TRUE)
  testthat::expect_match(html, "Select project vqa-demo2-min with 4 assessments", fixed = TRUE)
  testthat::expect_length(gregexpr('aria-label="Select project ', html, fixed = TRUE)[[1]], 2L)
})
