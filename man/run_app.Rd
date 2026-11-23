\name{run_app}
\alias{run_app}
\title{Run the OpenVQA Dashboard}
\usage{
run_app(options = list(), config_file = "config.yaml")
}
\arguments{
  \item{options}{A list of options passed to \code{shiny::shinyApp},
  such as \code{list(launch.browser = FALSE)}. These override settings from
  the configuration file.}
  \item{config_file}{Path to a required YAML settings file, relative to the
  working directory or absolute. Copy the root \file{config-template.yaml} to
  \file{config.yaml} when running from the repository. User values override
  shared settings bundled in \file{inst/default-config.yaml}. The file must contain
  a \code{default} profile; \env{R_CONFIG_ACTIVE} selects another profile
  that inherits from it. The optional \code{openvqa_dir} and \code{projects_dir}
  settings identify the backend checkout and project collection respectively.
  Relative installation paths resolve against this file's directory without
  changing the process working directory; absolute paths and \code{~} are supported.}
}
\description{Creates the OpenVQA Shiny application.}
\value{A Shiny application object. Print it to launch the application.}
