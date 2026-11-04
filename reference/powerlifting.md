# Historical OpenPowerlifting competition performances

A prepared extract of complete three-lift competition performances from
the OpenPowerlifting database. Records missing a positive squat, bench
press, deadlift, total, or bodyweight were removed. The data are an
historical snapshot and a person can occur more than once across
competitions.

## Usage

``` r
data(powerlifting)
```

## Format

A data frame with one row per competition performance and 11 fields:

- sex:

  Competition sex category: `F` or `M`.

- equipment:

  Equipment category.

- age:

  Age in years; may be missing.

- bodyweight_kg:

  Recorded bodyweight in kilograms.

- weight_class_kg:

  Meet-reported weight class.

- squat_kg:

  Best successful squat in kilograms.

- bench_kg:

  Best successful bench press in kilograms.

- deadlift_kg:

  Best successful deadlift in kilograms.

- total_kg:

  Official three-lift total in kilograms.

- place:

  Meet-reported placing, including non-numeric statuses.

- wilks:

  Meet-reported Wilks score; may be missing.

## Source

OpenPowerlifting, historical database extract distributed through
<https://www.kaggle.com/open-powerlifting/powerlifting-database>.
Current project documentation is at
<https://openpowerlifting.gitlab.io/opl-csv/bulk-csv-docs.html>.
