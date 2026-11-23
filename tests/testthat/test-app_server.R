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
    testthat::expect_null(selected_project())
    testthat::expect_null(selected_assessment())
    session$setInputs(project_id = "project_1", assessment_id = "assessment_2")
    testthat::expect_equal(selected_project()$name, "a_project")
    testthat::expect_equal(selected_assessment()$name, "same")
    session$setInputs(project_id = "../a_project")
    testthat::expect_error(selected_project(), "Invalid project selection")
    session$setInputs(project_id = "project_1", assessment_id = "../../outside")
    testthat::expect_error(selected_assessment(), "Invalid assessment selection")
  })
})

testthat::test_that("server reports setup, empty and unavailable collections", {
  shiny::testServer(app_server, {
    shiny::shinyOptions(golem_options = list())
    testthat::expect_match(output$backend_status$html, "Set openvqa_dir")
    testthat::expect_match(output$backend_status$html, "text-danger", fixed = TRUE)
    testthat::expect_match(output$projects_status, "Set projects_dir")
    testthat::expect_null(output$project_cards)
    testthat::expect_equal(output$projects_source, "Not configured")
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
