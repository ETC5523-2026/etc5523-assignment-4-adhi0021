# bonafide: Powerlifting Peer Benchmarker

**Package website:** <https://etc5523-2026.github.io/etc5523-assignment-4-adhi0021/> (function reference, data documentation and the [Get started vignette](https://etc5523-2026.github.io/etc5523-assignment-4-adhi0021/articles/using-bonafide.html)).

`bonafide` is an R package and Shiny app for powerlifters and coaches. It asks:

> How does a lifter's performance compare with similar competitors, and which of the squat, bench press, or deadlift appears to offer the greatest opportunity for improvement?

The app compares an entered three-lift performance with historical competition records of the same sex and equipment category within a chosen bodyweight window. Optional age matching provides a closer—but usually smaller—peer group.

## Data

The included `powerlifting` data are a prepared historical extract from the [OpenPowerlifting database](https://www.kaggle.com/open-powerlifting/powerlifting-database), published as **CC0: Public Domain**. The reproducible script in `data-raw/prepare_powerlifting.R` reads `data-raw/openpowerlifting.csv`, selects and renames relevant fields, and retains complete, positive three-lift performances. Current field definitions are available in the [OpenPowerlifting CSV documentation](https://openpowerlifting.gitlab.io/opl-csv/bulk-csv-docs.html).

Rows represent competition performances rather than unique people, so repeat competitors can occur. The extract has no meet date, federation, or location fields. Results therefore describe this historical sample and should not be interpreted as trends, current rankings, or causal training advice.

## Installation

Install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("ETC5523-2026/etc5523-assignment-4-adhi0021")
```

## Launch the app

```r
library(bonafide)
run_powerlifting_app()
```

The app opens in a browser or the IDE viewer. Choose the sex and equipment category, enter bodyweight and the three best lifts, and the percentile chart, peer-total histogram and plain-language summary update automatically. Notes in the sidebar and under each chart explain the fields and how to read the outputs. To stop the app, close it and press Esc in the R console.

## Data preparation

`data-raw/prepare_powerlifting.R` rebuilds `data/powerlifting.rda` from the raw CSV. From the package root, run:

```r
source("data-raw/prepare_powerlifting.R")
```

The package also supports programmatic comparison:

```r
result <- compare_lifter(
  powerlifting,
  sex = "F", equipment = "Raw", bodyweight = 63,
  squat = 110, bench = 60, deadlift = 140
)

result$summary
```

Package documentation and the vignette are published at <https://etc5523-2026.github.io/etc5523-assignment-4-adhi0021/>.

## Generative AI declaration

Generative AI declaration: I used ChatGPT to help plan the user question; data-preparation script robustness, documentation and styling. I used Claude Code to diagnose why the pkgdown website was not loading, to revise the Shiny app's validation and robustness, interpretation text and charts. I checked and revised the generated code and text and remain responsible for the submitted work.

## Licence

Package code is licensed under the MIT License. The OpenPowerlifting source data are released under CC0 and are attributed above.
