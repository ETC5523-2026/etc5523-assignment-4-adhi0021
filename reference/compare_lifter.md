# Compare a lifter with similar competition performances

Filters historical competition results by sex, equipment and a
bodyweight window, optionally adding an age window. It then calculates
empirical percentiles for squat, bench press, deadlift and total. A
percentile is the percentage of matching performances less than or equal
to the entered lift.

## Usage

``` r
compare_lifter(
  data = NULL,
  sex,
  equipment,
  bodyweight,
  squat,
  bench,
  deadlift,
  age = NULL,
  bodyweight_tolerance = 5,
  age_tolerance = 5,
  min_n = 30
)
```

## Arguments

- data:

  A data frame with the same fields as
  [powerlifting](https://etc5523-2026.github.io/etc5523-assignment-4-adhi0021/reference/powerlifting.md),
  or `NULL` to use the packaged data.

- sex:

  One of `"F"` or `"M"`.

- equipment:

  One of `"Raw"`, `"Wraps"`, `"Single-ply"`, or `"Multi-ply"`.

- bodyweight:

  Bodyweight in kilograms.

- squat, bench, deadlift:

  Best successful lifts in kilograms.

- age:

  Optional age in years. If `NULL`, age is not used for matching.

- bodyweight_tolerance:

  Maximum difference in bodyweight, in kilograms, for a performance to
  be considered similar.

- age_tolerance:

  Maximum age difference in years when `age` is supplied.

- min_n:

  Minimum desired peer-group size. The result is still returned below
  this threshold, with `weak_sample` set to `TRUE`.

## Value

A list containing `summary`, a four-row data frame of lift values and
percentiles; `peers`, the filtered records; `n`, the peer count;
`weak_sample`; `weakest_lift`; and the applied `filters`.

## Examples

``` r
result <- compare_lifter(
  powerlifting, sex = "F", equipment = "Raw", bodyweight = 63,
  squat = 110, bench = 60, deadlift = 140
)
result$summary
#>                 lift entered_kg peer_median_kg percentile
#> squat_kg       Squat        110          102.5       64.7
#> bench_kg       Bench         60           57.5       59.2
#> deadlift_kg Deadlift        140          127.5       70.1
#> total_kg       Total        310          290.0       65.0
result$weakest_lift
#> [1] "Bench"
```
