library(shiny)
library(ggplot2)
library(bslib)

# Data come from the installed package, not from an external file.
data("powerlifting", package = "bonafide", envir = environment())

lift_colours <- c(Squat = "#315c6b", Bench = "#e08f3e",
                  Deadlift = "#b33a3a", Total = "#6e5687")
min_peers <- 30

app_theme <- bs_theme(
  version = 5,
  bg = "#f7f4ef",
  fg = "#1d2a32",
  primary = "#b33a3a",
  secondary = "#315c6b",
  # local = FALSE links to Google Fonts instead of downloading at start-up,
  # so the app still launches (with fallback fonts) when offline.
  base_font = font_collection(font_google("Inter", local = FALSE),
                              "system-ui", "sans-serif"),
  heading_font = font_collection(font_google("Barlow Condensed", local = FALSE),
                                 "Arial Narrow", "sans-serif")
)

# Small helper so every input has an inline explanation beneath it.
field_help <- function(...) p(class = "field-help", ...)

ui <- page_navbar(
  title = div(class = "brand", "BONAFIDE", span("POWERLIFTING BENCHMARKER")),
  theme = app_theme,
  window_title = "Bonafide Powerlifting Benchmarker",
  header = tags$head(
    tags$style(HTML("
      .navbar { border-bottom: 4px solid #b33a3a; }
      .brand { font-weight: 800; letter-spacing: .08em; }
      .brand span { color: #f2c14e; font-size: .72rem; margin-left: .5rem; }
      .hero { background: linear-gradient(125deg,#17242c,#315c6b); color:white;
              border-radius:1rem; padding:1.4rem 1.7rem; margin-bottom:1rem; }
      .hero h1 { margin:0 0 .6rem; font-size:2.35rem; }
      .hero p { margin:.25rem 0; max-width:62rem; color:#e8edef; }
      .hero .tag { display:inline-block; min-width:5.5rem; font-weight:700;
                   color:#f2c14e; text-transform:uppercase; font-size:.8rem;
                   letter-spacing:.06em; }
      .card { border:0; box-shadow:0 5px 18px rgba(25,38,46,.09); }
      .value-box { min-height:120px; }
      .control-note, .field-help { color:#5c6970; font-size:.83rem; }
      .field-help { margin:-.6rem 0 .9rem; line-height:1.3; }
      .sidebar h5 { margin-top:.6rem; color:#315c6b; font-weight:700; }
      .weak-state { background:#fff3cd; border-left:5px solid #e0a800;
                    padding:.9rem 1rem; border-radius:.35rem; }
      .empty-state { background:#f8d7da; border-left:5px solid #b33a3a;
                     padding:.9rem 1rem; border-radius:.35rem; }
      .good-state { background:#e5f2ed; border-left:5px solid #28735a;
                    padding:.9rem 1rem; border-radius:.35rem; }
      .interpretation { font-size:1.02rem; line-height:1.55; }
      .interpretation strong { color:#8e2525; }
      .shiny-output-error-validation { color:#8e2525; font-weight:600;
                                       padding:1rem; }
      .footer-note { color:#67737a; font-size:.85rem; margin:1rem 0; }
      .glossary td:first-child { font-weight:600; white-space:nowrap; }
    "))
  ),
  nav_panel(
    "Benchmark",
    div(
      class = "container-fluid py-3",
      div(
        class = "hero",
        h1("How do your lifts compare?"),
        p(span(class = "tag", "Who"),
          "Competitive powerlifters and their coaches."),
        p(span(class = "tag", "Question"),
          "Compared with similar historical competitors, how strong is this",
          "lifter's performance, and which of the squat, bench press or",
          "deadlift offers the greatest relative room to improve?")
      ),
      layout_sidebar(
        sidebar = sidebar(
          width = 340,
          h5("1. Who to compare against"),
          selectInput("sex", "Competition sex", c("Women" = "F", "Men" = "M")),
          field_help("The sex category the lifter competes in."),
          selectInput("equipment", "Equipment",
                      c("Raw", "Wraps", "Single-ply", "Multi-ply")),
          field_help("Raw = no supportive suit; Wraps = knee wraps allowed;",
                     "Single-/Multi-ply = supportive suits and shirts."),
          numericInput("bodyweight", "Bodyweight (kg)", 75,
                       min = 30, max = 250, step = 0.5),
          sliderInput("bw_tol", "Bodyweight matching window (± kg)",
                      min = 1, max = 15, value = 5),
          field_help("Peers must be within this many kg of the bodyweight.",
                     "Wider = more peers but a looser comparison."),
          checkboxInput("use_age", "Also match by age", FALSE),
          conditionalPanel(
            "input.use_age",
            numericInput("age", "Age (years)", 30, min = 14, max = 100),
            sliderInput("age_tol", "Age matching window (± years)",
                        min = 1, max = 15, value = 5),
            field_help("Age is missing for some records, so age matching",
                       "usually shrinks the peer group.")
          ),
          h5("2. The performance to benchmark"),
          numericInput("squat", "Best squat (kg)", 150, min = 1, step = 2.5),
          numericInput("bench", "Best bench press (kg)", 100, min = 1, step = 2.5),
          numericInput("deadlift", "Best deadlift (kg)", 180, min = 1, step = 2.5),
          field_help("Best successful attempt in one competition. The total",
                     "is calculated as squat + bench + deadlift."),
          p(class = "control-note mt-2",
            "Results update automatically. Tip: start without age matching,",
            "then narrow the windows while the peer group stays above",
            min_peers, "records.")
        ),
        uiOutput("state_message"),
        layout_columns(
          value_box(title = "Entered total", value = textOutput("total_value"),
                    showcase = "Σ", theme = "primary"),
          value_box(title = "Comparable performances",
                    value = textOutput("peer_value"),
                    showcase = "≋", theme = "secondary"),
          value_box(title = "Lowest-percentile lift",
                    value = textOutput("weakest_value"),
                    showcase = "↗", theme = "warning"),
          col_widths = c(4, 4, 4)
        ),
        card(
          card_header("What this means"),
          uiOutput("interpretation")
        ),
        layout_columns(
          card(
            card_header("Percentile by lift"),
            p(class = "control-note",
              "Each bar is the % of comparable performances at or below your",
              "lift. The dashed line at 50% is the typical peer. The shortest",
              "of the three lift bars is the relative weak point."),
            plotOutput("percentile_plot", height = 320)
          ),
          card(
            card_header("Your total among peer totals"),
            p(class = "control-note",
              "Bars show how many peers recorded each total. The red line is",
              "your total and the dashed line is the peer median; more of the",
              "distribution to the left of the red line means a stronger result."),
            plotOutput("total_plot", height = 320)
          ),
          col_widths = c(6, 6)
        ),
        card(
          card_header("Detailed benchmark"),
          p(class = "control-note",
            "Gap to median is your lift minus the peer median: positive values",
            "are above a typical peer."),
          tableOutput("summary_table")
        ),
        p(class = "footer-note",
          "Descriptive competition benchmarks only, not causal evidence or a",
          "training programme. Data: OpenPowerlifting (CC0) historical extract.")
      )
    )
  ),
  nav_panel(
    "Guide & limitations",
    div(
      class = "container py-4",
      layout_columns(
        col_widths = c(6, 6),
        card(
          card_header("How to use the benchmark"),
          card_body(
            tags$ol(
              tags$li("Pick the competition sex and equipment category."),
              tags$li("Enter bodyweight and the three best successful lifts."),
              tags$li("Check the peer-group message: green means enough",
                      "records, amber means too few to trust, red means none."),
              tags$li("Read the percentile chart: the lowest of the three lift",
                      "bars is the relative weak point."),
              tags$li("Widen or narrow the bodyweight window (or add age) and",
                      "see whether the weak point stays the same. A result",
                      "that holds across windows is more trustworthy.")
            )
          )
        ),
        card(
          card_header("Fields"),
          card_body(
            tags$table(
              class = "table table-sm glossary",
              tags$tbody(
                tags$tr(tags$td("Sex"), tags$td("Competition category, F or M.")),
                tags$tr(tags$td("Equipment"), tags$td("Raw, Wraps, Single-ply or Multi-ply. Equipped lifts are typically heavier, so categories are never mixed.")),
                tags$tr(tags$td("Bodyweight"), tags$td("Weigh-in bodyweight in kg.")),
                tags$tr(tags$td("Matching window"), tags$td("How far (±) a peer's bodyweight or age may be from the entered value.")),
                tags$tr(tags$td("Squat / Bench / Deadlift"), tags$td("Best successful attempt in kg.")),
                tags$tr(tags$td("Percentile"), tags$td("Share of peers at or below the entered lift. 70% means the lift equals or beats 70% of peers.")),
                tags$tr(tags$td("Peer median"), tags$td("The middle peer value: half of peers lifted more, half less."))
              )
            )
          )
        )
      ),
      card(
        card_header("Interpret carefully"),
        card_body(
          tags$ul(
            tags$li("Rows are competition performances, not unique athletes; repeat competitors can influence the distribution."),
            tags$li("This is a historical snapshot (to 2019) and should not be read as a current ranking."),
            tags$li("Federations apply different rules and judging standards, which are not in this extract."),
            tags$li("Percentiles are relative: a low bench percentile means the bench is weak compared with these peers, not that bench training will be the most effective use of time. Discuss with a qualified coach."),
            tags$li("With fewer than ", min_peers, " matching records, percentiles move a lot with each extra record, so the app flags the result as unreliable.")
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # Step 1: collect and validate the inputs. debounce() waits until the user
  # stops typing so the benchmark is not recomputed on every keystroke.
  lifter_inputs <- reactive({
    validate(
      need(isTruthy(input$bodyweight) && input$bodyweight >= 30 &&
             input$bodyweight <= 250,
           "Enter a bodyweight between 30 and 250 kg."),
      need(isTruthy(input$squat) && input$squat > 0,
           "Enter a positive best squat (kg)."),
      need(isTruthy(input$bench) && input$bench > 0,
           "Enter a positive best bench press (kg)."),
      need(isTruthy(input$deadlift) && input$deadlift > 0,
           "Enter a positive best deadlift (kg)."),
      need(!isTRUE(input$use_age) ||
             (isTruthy(input$age) && input$age >= 14 && input$age <= 100),
           "Enter an age between 14 and 100, or untick age matching.")
    )
    total <- input$squat + input$bench + input$deadlift
    validate(need(total <= 1500,
                  paste0("A total of ", total, " kg is above any recorded ",
                         "result. Check the units (kg, not lb) and values.")))

    list(
      sex = input$sex, equipment = input$equipment,
      bodyweight = input$bodyweight, bw_tol = input$bw_tol,
      age = if (isTRUE(input$use_age)) input$age else NULL,
      age_tol = if (is.null(input$age_tol)) 5 else input$age_tol,
      squat = input$squat, bench = input$bench, deadlift = input$deadlift
    )
  }) |> debounce(400)

  # Step 2: run the exported package function on the packaged data.
  result <- reactive({
    x <- lifter_inputs()
    bonafide::compare_lifter(
      powerlifting,
      sex = x$sex, equipment = x$equipment, bodyweight = x$bodyweight,
      squat = x$squat, bench = x$bench, deadlift = x$deadlift,
      age = x$age, bodyweight_tolerance = x$bw_tol,
      age_tolerance = x$age_tol, min_n = min_peers
    )
  })

  # Step 3: every output below reads result().
  output$state_message <- renderUI({
    x <- result()
    if (x$n == 0) {
      div(class = "empty-state mb-3", strong("No comparable performances. "),
          "No ", x$filters$sex, " / ", x$filters$equipment,
          " records fall in this window. Widen the bodyweight or age window,",
          " untick age matching, or check the bodyweight and equipment.")
    } else if (x$weak_sample) {
      div(class = "weak-state mb-3", strong("Small comparison group. "),
          paste0("Only ", x$n, " records match (fewer than ", min_peers,
                 "). Percentiles are shown but are unstable; widen a matching ",
                 "window before drawing conclusions."))
    } else {
      div(class = "good-state mb-3",
          strong("A useful comparison group was found. "),
          paste("Percentiles use", format(x$n, big.mark = ","),
                "matching competition performances."))
    }
  })

  output$total_value <- renderText({
    paste0(format(result()$summary$entered_kg[4], nsmall = 0), " kg")
  })
  output$peer_value <- renderText(format(result()$n, big.mark = ","))
  output$weakest_value <- renderText({
    x <- result()
    if (x$n == 0 || is.na(x$weakest_lift)) "Not available" else x$weakest_lift
  })

  output$interpretation <- renderUI({
    x <- result()
    if (x$n == 0) {
      return(p(class = "interpretation",
               "There is nothing to compare against yet. Change the filters",
               "until the peer-group message turns green or amber."))
    }
    s <- x$summary
    lifts <- s[1:3, ]
    strongest <- lifts$lift[which.max(lifts$percentile)]
    total_pct <- s$percentile[4]
    spread <- max(lifts$percentile) - min(lifts$percentile)
    balance <- if (spread < 10) {
      "The three lifts sit within 10 percentile points of each other, so the profile is fairly balanced and no single lift stands out as a priority."
    } else {
      paste0("The ", tolower(x$weakest_lift), " is ", round(spread), " percentile points behind the ",
             tolower(strongest), ", so the ", tolower(x$weakest_lift),
             " offers the most relative room to improve against these peers.")
    }
    div(
      class = "interpretation",
      p(HTML(paste0(
        "This total of <strong>", s$entered_kg[4], " kg</strong> equals or beats <strong>",
        total_pct, "%</strong> of ", format(x$n, big.mark = ","), " comparable ",
        if (x$filters$sex == "F") "women's " else "men's ", tolower(x$filters$equipment),
        " performances. The strongest lift relative to peers is the <strong>",
        tolower(strongest), "</strong> (percentile ", max(lifts$percentile), "%) and the ",
        "weakest is the <strong>", tolower(x$weakest_lift), "</strong> (percentile ",
        min(lifts$percentile), "%)."
      ))),
      p(balance),
      if (x$weak_sample) p(class = "control-note",
                           "Caution: the peer group is small, so treat these numbers as rough.")
    )
  })

  output$percentile_plot <- renderPlot({
    x <- result()
    validate(need(x$n > 0, "No matching data to plot. Widen the matching window."))
    d <- x$summary
    d$lift <- factor(d$lift, levels = rev(c("Squat", "Bench", "Deadlift", "Total")))
    ggplot(d, aes(x = lift, y = percentile, fill = lift)) +
      geom_col(width = 0.68, show.legend = FALSE) +
      geom_hline(yintercept = 50, linetype = "dashed", colour = "#1d2a32") +
      annotate("text", x = 4.45, y = 50, label = "typical peer (50%)",
               hjust = -0.05, size = 3.4, colour = "#1d2a32") +
      geom_text(aes(label = paste0(percentile, "%")), hjust = -0.15,
                fontface = "bold") +
      coord_flip(clip = "off") +
      scale_y_continuous(limits = c(0, 110), breaks = seq(0, 100, 25),
                         labels = function(z) paste0(z, "%")) +
      scale_fill_manual(values = lift_colours) +
      labs(x = NULL, y = "Percentile among comparable performances") +
      theme_minimal(base_size = 13) +
      theme(panel.grid.major.y = element_blank(),
            axis.text.y = element_text(face = "bold"),
            plot.margin = margin(12, 30, 5.5, 5.5))
  })

  output$total_plot <- renderPlot({
    x <- result()
    validate(need(x$n > 0, "No matching data to plot. Widen the matching window."))
    entered_total <- x$summary$entered_kg[4]
    peer_median <- x$summary$peer_median_kg[4]
    ggplot(x$peers, aes(x = total_kg)) +
      geom_histogram(bins = if (x$n < 100) 15 else 32,
                     fill = "#8ba6af", colour = "white") +
      geom_vline(xintercept = peer_median, linetype = "dashed", colour = "#1d2a32") +
      geom_vline(xintercept = entered_total, colour = "#b33a3a", linewidth = 1.3) +
      annotate("label", x = entered_total, y = Inf, vjust = 1.3,
               label = paste0("You: percentile ", x$summary$percentile[4], "%"),
               colour = "#8e2525", fontface = "bold", size = 3.6) +
      labs(x = "Three-lift total (kg)", y = "Competition performances") +
      theme_minimal(base_size = 13)
  })

  output$summary_table <- renderTable({
    x <- result()
    validate(need(x$n > 0, "No matching performances. Change the filters to see a benchmark."))
    out <- x$summary
    out$gap <- out$entered_kg - out$peer_median_kg
    out <- out[, c("lift", "entered_kg", "peer_median_kg", "gap", "percentile")]
    out$percentile <- paste0(out$percentile, "%")
    out$gap <- sprintf("%+.1f", out$gap)
    names(out) <- c("Lift", "Your result (kg)", "Peer median (kg)",
                    "Gap to median (kg)", "Percentile")
    out
  }, striped = TRUE, hover = TRUE, bordered = FALSE, spacing = "m", digits = 1)
}

shinyApp(ui, server)
