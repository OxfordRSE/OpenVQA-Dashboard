#' Require an accessible directory and resolve its real filesystem location.
#'
#' @param path One directory path.
#' @return An absolute path with symlinks resolved and forward slashes.
#'   Stops if the directory cannot be read or traversed; never creates it.
#' @noRd
readable_directory <- function(path) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    stop("Directory must be a non-empty path.", call. = FALSE)
  }
  # Reading directory names and traversing their entries need separate permissions on POSIX.
  if (!dir.exists(path) || file.access(path, 4L) != 0L || file.access(path, 1L) != 0L) {
    stop("Directory is missing or unreadable: ", path, ". Check its path and permissions.",
      call. = FALSE
    )
  }
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

#' Test whether canonical paths are strictly below a canonical collection root.
#'
#' @param path Character vector of absolute, symlink-resolved paths.
#' @param root One canonical collection directory, as returned by readable_directory().
#' @return A logical vector. The root itself is not a selectable child.
#' @noRd
path_in_collection <- function(path, root) {
  if (.Platform$OS.type == "windows") {
    path <- tolower(path)
    root <- tolower(root)
  }
  # The separator prevents a sibling such as /data-backup from matching /data.
  startsWith(path, paste0(sub("/+$", "", root), "/"))
}

#' Check backend connectivity without loading its R code or dependencies.
#'
#' @param path Backend checkout directory, or NULL when not configured.
#' @return A list with status (setup, unavailable or ok), a display message and
#'   version (NULL unless connected). Filesystem failures become unavailable status.
#' @noRd
local_backend_status <- function(path) {
  if (is.null(path)) {
    return(list(
      status = "setup", message = "Set openvqa_dir in your settings file.", version = NULL
    ))
  }
  tryCatch(
    {
      path <- readable_directory(path)
      required <- file.path(path, c("validate.R", "analyse.R", "VERSION"))
      missing <- !file.exists(required) | dir.exists(required) | file.access(required, 4L) != 0L
      if (any(missing)) {
        stop(
          "Missing or unreadable backend files: ",
          paste(basename(required[missing]), collapse = ", "),
          ". Check openvqa_dir points to a supported OpenVQA checkout.",
          call. = FALSE
        )
      }
      # Read a second line to detect malformed metadata without invoking the CLI.
      version <- trimws(readLines(file.path(path, "VERSION"), n = 2L, warn = FALSE))
      if (length(version) != 1L || !nzchar(version)) {
        stop("VERSION must contain one non-empty version line.", call. = FALSE)
      }
      list(
        status = "ok", version = version,
        message = paste0(
          "OpenVQA ", version, " connected. Filesystem checks only; analysis readiness ",
          "has not been checked."
        )
      )
    },
    error = function(error) {
      list(
        status = "unavailable", message = paste("OpenVQA unavailable:", conditionMessage(error)),
        version = NULL
      )
    }
  )
}

#' List immediate directory children that stay within a collection.
#'
#' @param path Parent directory to list.
#' @param root Canonical collection directory used for containment checks.
#' @return Sorted child paths, retaining folder names for display. Escaping
#'   symlinks are excluded; inaccessible children inside the collection cause errors.
#' @noRd
collection_directories <- function(path, root) {
  readable_directory(path)
  children <- sort(list.dirs(path, full.names = TRUE, recursive = FALSE), method = "radix")
  canonical <- normalizePath(children, winslash = "/", mustWork = TRUE)
  children <- children[path_in_collection(canonical, root)]
  # Fail the scan rather than misreporting inaccessible data as an empty collection.
  invisible(lapply(children, readable_directory))
  children
}

#' Build a read-only catalogue from project/assessment/inputs directories.
#'
#' @param path Collection directory, or NULL when not configured.
#' @return A list with status (setup, unavailable, empty or ok), message and projects.
#'   Successful scans include the canonical root in path. Projects are keyed by
#'   project_N IDs and contain name, canonical path and an assessments list keyed
#'   by assessment_N IDs. Assessments contain name and canonical path. IDs belong
#'   to this catalogue snapshot; filesystem errors return unavailable with no projects.
#' @noRd
discover_projects <- function(path) {
  if (is.null(path)) {
    return(list(
      status = "setup", message = "Set projects_dir in your settings file.", projects = list()
    ))
  }
  tryCatch(
    {
      root <- readable_directory(path)
      projects <- list()
      # Fixed-depth discovery avoids treating nested backups or outputs as assessments.
      for (project in collection_directories(root, root)) {
        assessments <- list()
        for (assessment in collection_directories(project, root)) {
          inputs <- file.path(assessment, "inputs")
          if (!dir.exists(inputs)) {
            next
          }
          canonical <- normalizePath(inputs, winslash = "/", mustWork = TRUE)
          if (!path_in_collection(canonical, root)) {
            next
          }
          readable_directory(inputs)
          # IDs keep browser input separate from folder names and filesystem paths.
          assessments[[paste0("assessment_", length(assessments) + 1L)]] <- list(
            name = basename(assessment), path = readable_directory(assessment)
          )
        }
        if (length(assessments)) {
          projects[[paste0("project_", length(projects) + 1L)]] <- list(
            name = basename(project), path = readable_directory(project), assessments = assessments
          )
        }
      }
      list(
        status = if (length(projects)) "ok" else "empty", path = root, projects = projects,
        message = if (length(projects)) {
          paste("Projects connected:", length(projects), "project(s) discovered.")
        } else {
          "No projects found. Expected projects_dir/<project>/<assessment>/inputs/."
        }
      )
    },
    error = function(error) {
      list(
        status = "unavailable", message = paste("Projects unavailable:", conditionMessage(error)),
        projects = list()
      )
    }
  )
}

#' Resolve untrusted browser IDs against a server-owned catalogue snapshot.
#'
#' @param catalogue Result of discover_projects().
#' @param project_id A project ID from that catalogue, or NULL for no selection.
#' @param assessment_id An assessment ID within the project, or NULL to select the project.
#' @return The selected catalogue entry, or NULL with no project selection.
#'   Stops on invalid IDs, inaccessible paths or paths that now escape the root.
#'   Rechecks directory access without reading or modifying scientific inputs.
#' @noRd
resolve_catalogue_selection <- function(catalogue, project_id, assessment_id = NULL) {
  if (is.null(project_id)) {
    return(NULL)
  }
  valid_id <- function(id, entries) {
    is.character(id) && length(id) == 1L && !is.na(id) && id %in% names(entries)
  }
  if (catalogue$status != "ok" || !valid_id(project_id, catalogue$projects)) {
    stop("Invalid project selection. Reload the project collection.", call. = FALSE)
  }
  project <- catalogue$projects[[project_id]]
  selection <- project
  if (!is.null(assessment_id)) {
    if (!valid_id(assessment_id, project$assessments)) {
      stop("Invalid assessment selection. Reload the project collection.", call. = FALSE)
    }
    selection <- project$assessments[[assessment_id]]
  }
  # Files can change after discovery, so the cached catalogue alone is not sufficient.
  paths <- c(project$path, selection$path)
  for (path in paths) {
    canonical <- readable_directory(path)
    if (!identical(canonical, path) || !path_in_collection(canonical, catalogue$path)) {
      stop("Selected path is outside the collection or has changed. Reload the collection.",
        call. = FALSE
      )
    }
  }
  if (!is.null(assessment_id)) {
    inputs <- readable_directory(file.path(selection$path, "inputs"))
    if (!path_in_collection(inputs, catalogue$path)) {
      stop("Selected inputs are outside the collection.", call. = FALSE)
    }
  }
  selection
}
