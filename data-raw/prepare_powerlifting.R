# Prepare the historical OpenPowerlifting extract shipped with bonafide.
#
# Run from the package root with:
# source("data-raw/prepare_powerlifting.R")
#
# The raw file was obtained from the OpenPowerlifting database distribution
# published on Kaggle. It is retained in data-raw and excluded from the
# installed package.

raw_path <- "data-raw/openpowerlifting.csv"

if (!file.exists(raw_path)) {
  stop("Place openpowerlifting.csv in data-raw before running this script.")
}

raw <- read.csv(raw_path, stringsAsFactors = FALSE, na.strings = c("", "NA"))

required <- c(
  "Sex", "Equipment", "Age", "BodyweightKg", "WeightClassKg",
  "BestSquatKg", "BestBenchKg", "BestDeadliftKg", "TotalKg", "Place", "Wilks"
)

missing_columns <- setdiff(required, names(raw))
if (length(missing_columns) > 0) {
  stop("Raw data is missing: ", paste(missing_columns, collapse = ", "))
}

powerlifting <- data.frame(
  sex = raw$Sex,
  equipment = raw$Equipment,
  age = as.numeric(raw$Age),
  bodyweight_kg = as.numeric(raw$BodyweightKg),
  weight_class_kg = as.character(raw$WeightClassKg),
  squat_kg = as.numeric(raw$BestSquatKg),
  bench_kg = as.numeric(raw$BestBenchKg),
  deadlift_kg = as.numeric(raw$BestDeadliftKg),
  total_kg = as.numeric(raw$TotalKg),
  place = as.character(raw$Place),
  wilks = as.numeric(raw$Wilks),
  stringsAsFactors = FALSE
)

# The app benchmarks full three-lift performances. Remove records that cannot
# support that comparison and obvious non-positive measurements.
complete_lifts <- stats::complete.cases(
  powerlifting[, c("sex", "equipment", "bodyweight_kg", "squat_kg",
                    "bench_kg", "deadlift_kg", "total_kg")]
)
positive_lifts <- with(
  powerlifting,
  bodyweight_kg > 0 & squat_kg > 0 & bench_kg > 0 & deadlift_kg > 0 & total_kg > 0
)
powerlifting <- powerlifting[complete_lifts & positive_lifts, , drop = FALSE]
powerlifting <- powerlifting[powerlifting$sex %in% c("F", "M") &
                               powerlifting$equipment %in%
                               c("Raw", "Wraps", "Single-ply", "Multi-ply"), , drop = FALSE]

rownames(powerlifting) <- NULL

dir.create("data", showWarnings = FALSE)
save(powerlifting, file = "data/powerlifting.rda", compress = "xz", version = 2)

message("Saved ", format(nrow(powerlifting), big.mark = ","),
        " complete three-lift performances to data/powerlifting.rda")
