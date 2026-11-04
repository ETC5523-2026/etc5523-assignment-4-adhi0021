#' Launch the Powerlifting Peer Benchmarker
#'
#' Starts the Shiny application bundled with the package. The app lets a
#' lifter or coach compare a three-lift performance with historical competitors
#' of the same sex and equipment category at a similar bodyweight and,
#' optionally, age.
#'
#' @param ... Arguments passed to [shiny::runApp()], such as `launch.browser`.
#'
#' @return The value returned by [shiny::runApp()]. Called for its side effect.
#' @export
#' @importFrom bslib bs_theme
#' @importFrom ggplot2 ggplot
#'
#' @examples
#' if (interactive()) {
#'   run_powerlifting_app()
#' }
run_powerlifting_app <- function(...) {
  # These packages are used by the app script in inst/; checking them here also
  # gives a clearer failure than sourcing a partially constructed interface.
  if (!requireNamespace("bslib", quietly = TRUE) ||
      !requireNamespace("ggplot2", quietly = TRUE)) {
    stop("The app requires the bslib and ggplot2 packages.", call. = FALSE)
  }
  app_dir <- system.file("shiny-app", package = "bonafide")
  if (!nzchar(app_dir)) {
    stop("The bundled Shiny app could not be found. Reinstall bonafide.", call. = FALSE)
  }
  shiny::runApp(app_dir, ...)
}
