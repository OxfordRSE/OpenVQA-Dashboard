test_that("user settings inherit bundled application defaults", {
  path <- local_config_file()
  original <- readLines(path)
  app <- run_app(config_file = path)
  expect_equal(app$options$port, 8000)
  expect_equal(app$options$host, "127.0.0.1")
  expect_null(app$appOptions$golem_options$openvqa_dir)
  expect_equal(readLines(path), original)
})

test_that("the launcher reads config.yaml from the working directory", {
  path <- local_config_file()
  directory <- withr::local_tempdir()
  file.copy(path, file.path(directory, "config.yaml"))
  withr::local_dir(directory)
  expect_equal(run_app()$options$port, 8000)
  unlink("config.yaml")
  expect_error(run_app(), "Copy config-template.yaml to config.yaml", fixed = TRUE)
})

test_that("named profiles inherit shared settings", {
  path <- local_config_file()
  writeLines(c(
    "default:", "  openvqa_dir: '/local/OpenVQA'",
    "development:", "  openvqa_dir: '../OpenVQA'",
    "production:", "  openvqa_dir: '/opt/OpenVQA'"
  ), path)
  withr::local_envvar(R_CONFIG_ACTIVE = "development")
  app <- run_app(config_file = path)
  expect_equal(app$options$port, 8000)
  expect_equal(app$options$host, "127.0.0.1")
  expect_equal(app$appOptions$golem_options$openvqa_dir, "../OpenVQA")
  withr::local_envvar(R_CONFIG_ACTIVE = "production")
  expect_equal(
    run_app(config_file = path)$appOptions$golem_options$openvqa_dir,
    "/opt/OpenVQA"
  )
})

test_that("user fields override shared defaults without replacing sibling fields", {
  path <- local_config_file()
  writeLines(c(
    "default:", "  openvqa_dir: '/local/OpenVQA'", "  shiny:", "    port: 8123"
  ), path)
  app <- run_app(config_file = path)
  expect_equal(app$options$port, 8123)
  expect_equal(app$options$host, "127.0.0.1")
  expect_equal(app$appOptions$golem_options$openvqa_dir, "/local/OpenVQA")
})

test_that("explicit files and launch options are respected", {
  path <- local_config_file()
  app <- run_app(config_file = path, options = list(port = 8124, launch.browser = FALSE))
  expect_equal(app$options$port, 8124)
  expect_false(app$options$launch.browser)
  expect_null(run_app(config_file = path, options = list(port = NULL))$options$port)
  expect_error(run_app(config_file = paste0(path, ".missing")), "Settings file not found")
})

test_that("YAML can request an automatic port", {
  path <- local_config_file()
  writeLines(c(
    "default:", "  shiny:", "    host: '127.0.0.1'", "    port: null"
  ), path)
  expect_null(run_app(config_file = path)$options$port)
})

test_that("invalid settings are rejected", {
  path <- local_config_file()
  for (port in list(0, 65536, 8000.5, "8000", NA_real_)) {
    expect_error(run_app(config_file = path, options = list(port = port)), "Shiny port")
  }
  expect_error(run_app(config_file = path, options = list(host = "")), "Shiny host")
  writeLines(c("default:", "  shiny: false"), path)
  expect_error(run_app(config_file = path), "shiny.*section")
  writeLines(c(
    "default:", "  shiny:", "    host: '127.0.0.1'", "    port: 8000",
    "  openvqa_dir: false"
  ), path)
  expect_error(run_app(config_file = path), "OpenVQA directory")
  writeLines(c("shiny:", "  port: 8000"), path)
  expect_error(run_app(config_file = path), "must provide a default configuration")
})
