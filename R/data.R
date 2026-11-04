#' Historical OpenPowerlifting competition performances
#'
#' A prepared extract of complete three-lift competition performances from the
#' OpenPowerlifting database. Records missing a positive squat, bench press,
#' deadlift, total, or bodyweight were removed. The data are an historical
#' snapshot and a person can occur more than once across competitions.
#'
#' @format A data frame with one row per competition performance and 11 fields:
#' \describe{
#'   \item{sex}{Competition sex category: `F` or `M`.}
#'   \item{equipment}{Equipment category.}
#'   \item{age}{Age in years; may be missing.}
#'   \item{bodyweight_kg}{Recorded bodyweight in kilograms.}
#'   \item{weight_class_kg}{Meet-reported weight class.}
#'   \item{squat_kg}{Best successful squat in kilograms.}
#'   \item{bench_kg}{Best successful bench press in kilograms.}
#'   \item{deadlift_kg}{Best successful deadlift in kilograms.}
#'   \item{total_kg}{Official three-lift total in kilograms.}
#'   \item{place}{Meet-reported placing, including non-numeric statuses.}
#'   \item{wilks}{Meet-reported Wilks score; may be missing.}
#' }
#' @source OpenPowerlifting, historical database extract distributed through
#'   \url{https://www.kaggle.com/open-powerlifting/powerlifting-database}.
#'   Current project documentation is at
#'   \url{https://openpowerlifting.gitlab.io/opl-csv/bulk-csv-docs.html}.
#' @usage data(powerlifting)
"powerlifting"
