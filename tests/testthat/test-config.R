testthat::test_that("user settings inherit bundled application defaults", {
  path <- local_config_file()
  original <- readLines(path)
  app <- run_app(config_file = path)
  testthat::expect_equal(app$options$port, 8000)
  testthat::expect_equal(app$options$host, "127.0.0.1")
  testthat::expect_null(app$appOptions$golem_options$openvqa_dir)
  testthat::expect_equal(readLines(path), original)
})

testthat::test_that("the launcher reads config.yaml from the working directory", {
  path <- local_config_file()
  directory <- withr::local_tempdir()
  file.copy(path, file.path(directory, "config.yaml"))
  withr::local_dir(directory)
  testthat::expect_equal(run_app()$options$port, 8000)
  unlink("config.yaml")
  testthat::expect_error(run_app(), "Copy config-template.yaml to config.yaml", fixed = TRUE)
})

testthat::test_that("named profiles inherit shared settings", {
  path <- local_config_file()
  writeLines(c(
    "default:", "  openvqa_dir: '/local/OpenVQA'",
    "development:", "  openvqa_dir: '../OpenVQA'",
    "production:", "  openvqa_dir: '/opt/OpenVQA'"
  ), path)
  withr::local_envvar(R_CONFIG_ACTIVE = "development")
  app <- run_app(config_file = path)
  testthat::expect_equal(app$options$port, 8000)
  testthat::expect_equal(app$options$host, "127.0.0.1")
  testthat::expect_equal(app$appOptions$golem_options$openvqa_dir, "../OpenVQA")
  withr::local_envvar(R_CONFIG_ACTIVE = "production")
  testthat::expect_equal(
    run_app(config_file = path)$appOptions$golem_options$openvqa_dir,
    "/opt/OpenVQA"
  )
})

testthat::test_that("user fields override shared defaults without replacing sibling fields", {
  path <- local_config_file()
  writeLines(c(
    "default:", "  openvqa_dir: '/local/OpenVQA'", "  shiny:", "    port: 8123"
  ), path)
  app <- run_app(config_file = path)
  testthat::expect_equal(app$options$port, 8123)
  testthat::expect_equal(app$options$host, "127.0.0.1")
  testthat::expect_equal(app$appOptions$golem_options$openvqa_dir, "/local/OpenVQA")
})

testthat::test_that("explicit files and launch options are respected", {
  path <- local_config_file()
  app <- run_app(config_file = path, options = list(port = 8124, launch.browser = FALSE))
  testthat::expect_equal(app$options$port, 8124)
  testthat::expect_false(app$options$launch.browser)
  testthat::expect_null(run_app(config_file = path, options = list(port = NULL))$options$port)
  testthat::expect_error(run_app(config_file = paste0(path, ".missing")), "Settings file not found")
})

testthat::test_that("YAML can request an automatic port", {
  path <- local_config_file()
  writeLines(c(
    "default:", "  shiny:", "    host: '127.0.0.1'", "    port: null"
  ), path)
  testthat::expect_null(run_app(config_file = path)$options$port)
})

testthat::test_that("invalid settings are rejected", {
  path <- local_config_file()
  for (port in list(0, 65536, 8000.5, "8000", NA_real_)) {
    testthat::expect_error(run_app(config_file = path, options = list(port = port)), "Shiny port")
  }
  testthat::expect_error(run_app(config_file = path, options = list(host = "")), "Shiny host")
  writeLines(c("default:", "  shiny: false"), path)
  testthat::expect_error(run_app(config_file = path), "shiny.*section")
  writeLines(c(
    "default:", "  shiny:", "    host: '127.0.0.1'", "    port: 8000",
    "  openvqa_dir: false"
  ), path)
  testthat::expect_error(run_app(config_file = path), "OpenVQA directory")
  writeLines(c("shiny:", "  port: 8000"), path)
  testthat::expect_error(run_app(config_file = path), "must provide a default configuration")
})
