testthat::test_that("the launcher passes resolved settings to Shiny and golem", {
  path <- local_config_file()
  writeLines(c(
    "default:", "  openvqa_dir: '/local/OpenVQA'", "  projects_dir: '/local/projects'",
    "  shiny:", "    port: 8123"
  ), path)
  app <- run_app(config_file = path, options = list(port = 8124, launch.browser = FALSE))

  testthat::expect_s3_class(app, "shiny.appobj")
  testthat::expect_equal(app$options$host, "127.0.0.1")
  testthat::expect_equal(app$options$port, 8124)
  testthat::expect_false(app$options$launch.browser)
  testthat::expect_equal(app$appOptions$golem_options$openvqa_dir, "/local/OpenVQA")
  testthat::expect_equal(app$appOptions$golem_options$projects_dir, "/local/projects")
})
