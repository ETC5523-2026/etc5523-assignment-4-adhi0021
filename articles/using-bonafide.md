# Using the Powerlifting Peer Benchmarker

## Purpose

`bonafide` is designed for a powerlifter or coach asking:

> How does a lifter’s performance compare with similar competitors, and
> which lift appears to offer the greatest opportunity for improvement?

It provides a descriptive benchmark, not a training prescription. A
“peer” is a historical competition performance with the same sex and
equipment category and a bodyweight inside the selected window. Age can
also be included.

## Install and launch

Install from GitHub and launch the included app:

``` r

install.packages("remotes")
remotes::install_github("ETC5523-2026/etc5523-assignment-4-adhi0021")

library(bonafide)
run_powerlifting_app()
```

In the app, choose competition sex and equipment, enter bodyweight and
the three best successful lifts, then select **Compare performance**.
Start with the default ±5 kg bodyweight window. Age matching can produce
a more specific group but may make the comparison unstable when few
records remain.

## Use the comparison function

The app uses the exported
[`compare_lifter()`](https://etc5523-2026.github.io/etc5523-assignment-4-adhi0021/reference/compare_lifter.md)
function. The same analysis can be reproduced directly:

``` r

library(bonafide)

example_result <- compare_lifter(
  powerlifting,
  sex = "F",
  equipment = "Raw",
  bodyweight = 63,
  squat = 110,
  bench = 60,
  deadlift = 140,
  bodyweight_tolerance = 5
)

example_result$summary
#>                 lift entered_kg peer_median_kg percentile
#> squat_kg       Squat        110          102.5       64.7
#> bench_kg       Bench         60           57.5       59.2
#> deadlift_kg Deadlift        140          127.5       70.1
#> total_kg       Total        310          290.0       65.0
example_result$n
#> [1] 13921
example_result$weakest_lift
#> [1] "Bench"
```

The percentile is the percentage of matching competition performances at
or below the entered result. For example, a deadlift percentile of 70
means the entered deadlift equals or exceeds 70% of records in that peer
group. It does **not** mean that the athlete is 70% as strong as the
best competitor.

The lowest lift-specific percentile is labelled as a potential priority.
This conclusion is relative to the selected peer group. Technique,
injury history, programme phase, and coaching judgement are not in the
dataset.

## Weak states

The app checks for non-positive and implausibly large values. It also
reports when no peers match or when fewer than 30 records match. If the
sample is small, broaden the bodyweight window, turn off age matching,
or choose the correct equipment category before interpreting the chart.

## Data preparation and limitations

The script `data-raw/prepare_powerlifting.R` reproducibly creates the
packaged data from `openpowerlifting.csv`. It selects the documented
fields and keeps records with positive bodyweight and all three positive
lifts.

Important limitations are:

- a row is a competition performance, not a unique athlete;
- repeat competitors may therefore influence the distribution;
- incomplete and unsuccessful performances are excluded;
- this historical extract does not contain meet date, federation, or
  location; and
- judging standards and competition populations can differ across
  federations.

The app should therefore be used for exploration and informed
discussion, not current rankings, causal claims, or medical and training
advice.
