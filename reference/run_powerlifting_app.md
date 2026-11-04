# Launch the Powerlifting Peer Benchmarker

Starts the Shiny application bundled with the package. The app lets a
lifter or coach compare a three-lift performance with historical
competitors of the same sex and equipment category at a similar
bodyweight and, optionally, age.

## Usage

``` r
run_powerlifting_app(...)
```

## Arguments

- ...:

  Arguments passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html), such
  as `launch.browser`.

## Value

The value returned by
[`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html). Called
for its side effect.

## Examples

``` r
if (interactive()) {
  run_powerlifting_app()
}
```
