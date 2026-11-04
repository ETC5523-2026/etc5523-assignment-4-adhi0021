#' Compare a lifter with similar competition performances
#'
#' Filters historical competition results by sex, equipment and a bodyweight
#' window, optionally adding an age window. It then calculates empirical
#' percentiles for squat, bench press, deadlift and total. A percentile is the
#' percentage of matching performances less than or equal to the entered lift.
#'
#' @param data A data frame with the same fields as [powerlifting], or `NULL`
#'   to use the packaged data.
#' @param sex One of `"F"` or `"M"`.
#' @param equipment One of `"Raw"`, `"Wraps"`, `"Single-ply"`, or
#'   `"Multi-ply"`.
#' @param bodyweight Bodyweight in kilograms.
#' @param squat,bench,deadlift Best successful lifts in kilograms.
#' @param age Optional age in years. If `NULL`, age is not used for matching.
#' @param bodyweight_tolerance Maximum difference in bodyweight, in kilograms,
#'   for a performance to be considered similar.
#' @param age_tolerance Maximum age difference in years when `age` is supplied.
#' @param min_n Minimum desired peer-group size. The result is still returned
#'   below this threshold, with `weak_sample` set to `TRUE`.
#'
#' @return A list containing `summary`, a four-row data frame of lift values and
#'   percentiles; `peers`, the filtered records; `n`, the peer count;
#'   `weak_sample`; `weakest_lift`; and the applied `filters`.
#' @export
#'
#' @examples
#' result <- compare_lifter(
#'   powerlifting, sex = "F", equipment = "Raw", bodyweight = 63,
#'   squat = 110, bench = 60, deadlift = 140
#' )
#' result$summary
#' result$weakest_lift
compare_lifter <- function(data = NULL, sex, equipment, bodyweight,
                           squat, bench, deadlift, age = NULL,
                           bodyweight_tolerance = 5, age_tolerance = 5,
                           min_n = 30) {
  if (is.null(data)) {
    data <- bonafide::powerlifting
  }

  needed <- c("sex", "equipment", "age", "bodyweight_kg", "squat_kg",
              "bench_kg", "deadlift_kg", "total_kg")
  absent <- setdiff(needed, names(data))
  if (length(absent)) {
    stop("`data` is missing required columns: ", paste(absent, collapse = ", "),
         call. = FALSE)
  }

  scalar_number <- function(x, label, allow_null = FALSE) {
    if (allow_null && is.null(x)) return(NULL)
    if (length(x) != 1L || !is.numeric(x) || is.na(x) || !is.finite(x) || x <= 0) {
      stop("`", label, "` must be one positive, finite number.", call. = FALSE)
    }
    x
  }

  bodyweight <- scalar_number(bodyweight, "bodyweight")
  squat <- scalar_number(squat, "squat")
  bench <- scalar_number(bench, "bench")
  deadlift <- scalar_number(deadlift, "deadlift")
  age <- scalar_number(age, "age", allow_null = TRUE)
  bodyweight_tolerance <- scalar_number(bodyweight_tolerance, "bodyweight_tolerance")
  age_tolerance <- scalar_number(age_tolerance, "age_tolerance")
  min_n <- scalar_number(min_n, "min_n")

  if (length(sex) != 1L || !sex %in% c("F", "M")) {
    stop("`sex` must be 'F' or 'M'.", call. = FALSE)
  }
  valid_equipment <- c("Raw", "Wraps", "Single-ply", "Multi-ply")
  if (length(equipment) != 1L || !equipment %in% valid_equipment) {
    stop("`equipment` must be Raw, Wraps, Single-ply, or Multi-ply.", call. = FALSE)
  }

  keep <- !is.na(data$sex) & !is.na(data$equipment) &
    !is.na(data$bodyweight_kg) & data$sex == sex &
    data$equipment == equipment &
    abs(data$bodyweight_kg - bodyweight) <= bodyweight_tolerance

  if (!is.null(age)) {
    keep <- keep & !is.na(data$age) & abs(data$age - age) <= age_tolerance
  }

  peers <- data[keep, , drop = FALSE]
  total <- squat + bench + deadlift
  entered <- c(Squat = squat, Bench = bench, Deadlift = deadlift, Total = total)
  peer_columns <- c("squat_kg", "bench_kg", "deadlift_kg", "total_kg")

  percentiles <- vapply(seq_along(entered), function(i) {
    values <- peers[[peer_columns[i]]]
    values <- values[is.finite(values)]
    if (!length(values)) return(NA_real_)
    100 * mean(values <= entered[i])
  }, numeric(1))

  summary <- data.frame(
    lift = names(entered),
    entered_kg = unname(entered),
    peer_median_kg = vapply(peer_columns, function(column) {
      values <- peers[[column]]
      if (all(is.na(values)) || !length(values)) NA_real_ else stats::median(values, na.rm = TRUE)
    }, numeric(1)),
    percentile = round(percentiles, 1),
    stringsAsFactors = FALSE
  )

  lift_rows <- seq_len(3)
  weakest <- if (all(is.na(summary$percentile[lift_rows]))) {
    NA_character_
  } else {
    summary$lift[lift_rows][which.min(summary$percentile[lift_rows])]
  }

  list(
    summary = summary,
    peers = peers,
    n = nrow(peers),
    weak_sample = nrow(peers) < min_n,
    weakest_lift = weakest,
    filters = list(
      sex = sex, equipment = equipment, bodyweight = bodyweight, age = age,
      bodyweight_tolerance = bodyweight_tolerance, age_tolerance = age_tolerance
    )
  )
}
