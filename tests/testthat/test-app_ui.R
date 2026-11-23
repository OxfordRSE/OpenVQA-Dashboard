testthat::test_that("the homepage uses a bslib sidebar with source and version information", {
  html <- as.character(app_ui(NULL))
  testthat::expect_match(html, "bslib-page-sidebar", fixed = TRUE)
  testthat::expect_match(html, "Project source", fixed = TRUE)
  testthat::expect_match(html, 'id="projects_source"', fixed = TRUE)
  testthat::expect_match(html, paste0("R: v", getRversion()), fixed = TRUE)
  testthat::expect_match(html, "Dashboard: v", fixed = TRUE)
  testthat::expect_match(html, 'data-open-mobile="closed"', fixed = TRUE)
})
