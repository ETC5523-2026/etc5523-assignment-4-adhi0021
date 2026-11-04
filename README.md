# bonafide: Powerlifting Peer Benchmarker

`bonafide` is an R package and Shiny app for powerlifters and coaches. It asks:

> How does a lifter's performance compare with similar competitors, and which of the squat, bench press, or deadlift appears to offer the greatest opportunity for improvement?

The app compares an entered three-lift performance with historical competition records of the same sex and equipment category within a chosen bodyweight window. Optional age matching provides a closer—but usually smaller—peer group.

## Data

The included `powerlifting` data are a prepared historical extract from the [OpenPowerlifting database](https://www.kaggle.com/open-powerlifting/powerlifting-database), published as **CC0: Public Domain**. The reproducible script in `data-raw/prepare_powerlifting.R` reads `data-raw/openpowerlifting.csv`, selects and renames relevant fields, and retains complete, positive three-lift performances. Current field definitions are available in the [OpenPowerlifting CSV documentation](https://openpowerlifting.gitlab.io/opl-csv/bulk-csv-docs.html).

Rows represent competition performances rather than unique people, so repeat competitors can occur. The extract has no meet date, federation, or location fields. Results therefore describe this historical sample and should not be interpreted as trends, current rankings, or causal training advice.

## Installation

Install the development version from GitHub:

```{r}
# install.packages("remotes")
remotes::install_github("ETC5523-2026/etc5523-assignment-4-adhi0021")
```

## Launch the app

```{r}
library(bonafide)
run_powerlifting_app()
```

The package also supports programmatic comparison:

```{r}
result <- compare_lifter(
  powerlifting,
  sex = "F", equipment = "Raw", bodyweight = 63,
  squat = 110, bench = 60, deadlift = 140
)

result$summary
```

This function supports 6 list components: '$summary', '$peers', '$n', '$seak_sample', '$weakest_lift', '$filters'. The '$filter' component have its own elements.
W
Package documentation and the vignette are published at <https://etc5523-2026.github.io/etc5523-assignment-4-adhi0021/>.

## Generative AI declaration

Generative AI declaration: I used AI to help plan the user question; revise the R package, data-preparation script, Shiny application code help for errors, and styling. I checked and revised the generated code and text and remain responsible for the submitted work.

## Licence

Package code is licensed under the MIT License. The OpenPowerlifting source data are released under CC0 and are attributed above.
