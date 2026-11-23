testthat::test_that("server status and selection validation use configured catalogues", {
  root <- local_project_collection()
  backend_path <- local_backend()
  shiny::testServer(app_server, {
    shiny::shinyOptions(golem_options = list(openvqa_dir = backend_path, projects_dir = root))
    testthat::expect_match(output$backend_status$html, "OpenVQA: v0.1.0 - connected", fixed = TRUE)
    testthat::expect_match(output$backend_status$html, "text-success", fixed = TRUE)
    testthat::expect_match(output$projects_status, "2 project(s) discovered", fixed = TRUE)
    testthat::expect_equal(output$projects_source, root)
    testthat::expect_match(output$project_cards$html, "a_project", fixed = TRUE)
    testthat::expect_equal(output$selection_status, "Select a project.")
    testthat::expect_null(selected_project())
    testthat::expect_null(selected_assessment())
    session$setInputs(project_1 = 1, assessment_id = "assessment_2")
    testthat::expect_equal(selected_project()$name, "a_project")
    testthat::expect_equal(selected_assessment()$name, "same")
    testthat::expect_equal(output$selection_status, "Selected project: a_project")
    original_grid <- output$project_cards$html
    session$setInputs(project_2 = 1, assessment_id = NULL)
    testthat::expect_equal(selected_project()$name, "z_project")
    testthat::expect_equal(output$selection_status, "Selected project: z_project")
    testthat::expect_equal(output$project_cards$html, original_grid)
    session$setInputs(project_id = "../a_project", project_99 = 1)
    testthat::expect_equal(selected_project()$name, "z_project")
    testthat::expect_equal(output$selection_status, "Selected project: z_project")
    session$setInputs(project_1 = 2, assessment_id = "../../outside")
    testthat::expect_error(selected_assessment(), "Invalid assessment selection")
  })
})

testthat::test_that("server reports setup, empty and unavailable collections", {
  shiny::testServer(app_server, {
    shiny::shinyOptions(golem_options = list())
    testthat::expect_match(output$backend_status$html, "Set openvqa_dir")
    testthat::expect_match(output$backend_status$html, "text-danger", fixed = TRUE)
    testthat::expect_match(output$projects_status, "Set projects_dir")
    testthat::expect_equal(output$projects_source, "Not configured")
    testthat::expect_null(output$project_cards)
  })
  root <- withr::local_tempdir()
  shiny::testServer(app_server, {
    shiny::shinyOptions(golem_options = list(projects_dir = root))
    testthat::expect_match(output$projects_status, "No projects found")
    testthat::expect_null(output$project_cards)
  })
  shiny::testServer(app_server, {
    shiny::shinyOptions(golem_options = list(
      projects_dir = file.path(root, "missing"), openvqa_dir = file.path(root, "missing")
    ))
    testthat::expect_match(output$backend_status$html, "OpenVQA: unavailable - disconnected",
      fixed = TRUE
    )
    testthat::expect_match(output$backend_status$html, "text-danger", fixed = TRUE)
    testthat::expect_match(output$backend_status$html, "missing or unreadable", fixed = TRUE)
    testthat::expect_match(output$projects_status, "Projects unavailable")
    testthat::expect_null(output$project_cards)
  })
})

testthat::test_that("project selections belong to the current Shiny session", {
  root <- local_project_collection()
  for (id in c("project_1", "project_2")) {
    shiny::testServer(app_server, {
      shiny::shinyOptions(golem_options = list(projects_dir = root))
      testthat::expect_null(selected_project())
      click <- list(1)
      names(click) <- id
      do.call(session$setInputs, click)
      testthat::expect_equal(selected_project(), catalogue()$projects[[id]])
    })
  }
})

testthat::test_that("a removed project produces a useful selection error", {
  root <- local_project_collection()
  shiny::testServer(app_server, {
    shiny::shinyOptions(golem_options = list(projects_dir = root))
    projects <- catalogue()$projects
    # The displayed catalogue is a snapshot; clicking must still check the current filesystem.
    unlink(projects$project_1$path, recursive = TRUE)
    session$setInputs(project_1 = 1)
    testthat::expect_match(output$selection_status, "missing or unreadable")
  })
})

testthat::test_that("clicking the same card again rechecks its directory", {
  root <- local_project_collection()
  shiny::testServer(app_server, {
    shiny::shinyOptions(golem_options = list(projects_dir = root))
    session$setInputs(project_1 = 1)
    testthat::expect_equal(selected_project()$name, "a_project")
    unlink(selected_project()$path, recursive = TRUE)
    session$setInputs(project_1 = 2)
    testthat::expect_match(output$selection_status, "missing or unreadable")
  })
})
