# bonafide: Powerlifting Peer Benchmarker

`bonafide` is an R package and Shiny app that compares a powerlifter's squat, bench press, and deadlift against historical competition records. It helps athletes and coaches identify which lift offers the greatest opportunity for improvement based on sex, equipment, bodyweight, and age.

## Installation

```r
# install.packages("remotes")
remotes::install_github("ETC5523-2026/etc5523-assignment-4-adhi0021/bonafide")
```

## Launch the App

```r
library(bonafide)
run_powerlifting_app()
```

## Programmatic Usage

You can also compare lifts directly in the R console:

```r
result <- compare_lifter(
  powerlifting,
  sex = "F", equipment = "Raw", bodyweight = 63,
  squat = 110, bench = 60, deadlift = 140
)

# View results (returns list with summary, peers, n, weak_sample, weakest_lift, and filters)
result$summary
```

## Data & Resources

* **Documentation:** Full package documentation and vignettes are available [here](https://etc5523-2026.github.io/etc5523-assignment-4-adhi0021/bonafide).
* **Data Source:** Built using historical records from the [OpenPowerlifting database](https://www.kaggle.com/open-powerlifting/powerlifting-database) (CC0 Public Domain).
* **License:** Package code is licensed under the MIT License.
* **AI Declaration:** OpenAI Codex was utilized to assist in planning, scaffolding, and revising the R package code, documentation, and Shiny app.