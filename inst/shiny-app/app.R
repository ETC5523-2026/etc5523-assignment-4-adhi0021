library(shiny)
library(ggplot2)
library(bslib)

data("powerlifting", package = "bonafide")

app_theme <- bs_theme(
  version = 5,
  bg = "#f7f4ef",
  fg = "#1d2a32",
  primary = "#b33a3a",
  secondary = "#315c6b",
  base_font = font_google("Inter"),
  heading_font = font_google("Barlow Condensed")
)

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
              border-radius:1rem; padding:1.5rem 1.7rem; margin-bottom:1rem; }
      .hero h1 { margin:0 0 .4rem; font-size:2.35rem; }
      .hero p { margin:0; max-width:58rem; color:#e8edef; }
      .card { border:0; box-shadow:0 5px 18px rgba(25,38,46,.09); }
      .value-box { min-height:130px; }
      .control-note { color:#5c6970; font-size:.88rem; }
      .weak-state { background:#fff3cd; border-left:5px solid #e0a800;
                    padding:.9rem 1rem; border-radius:.35rem; }
      .good-state { background:#e5f2ed; border-left:5px solid #28735a;
                    padding:.9rem 1rem; border-radius:.35rem; }
      .footer-note { color:#67737a; font-size:.85rem; margin:1rem 0; }
    "))
  ),
  nav_panel(
    "Benchmark",
    div(
      class = "container-fluid py-3",
      div(
        class = "hero",
        h1("How do your lifts compare?"),
        p("For powerlifters and coaches: compare one three-lift performance with historical competitors of the same sex and equipment type at a similar bodyweight. The lowest lift percentile highlights a potential training priority—not a prescription.")
      ),
      layout_sidebar(
        sidebar = sidebar(
          width = 330,
          h4("Your competition performance"),
          selectInput("sex", "Competition sex", c("Women" = "F", "Men" = "M")),
          selectInput("equipment", "Equipment", c("Raw", "Wraps", "Single-ply", "Multi-ply")),
          numericInput("bodyweight", "Bodyweight (kg)", 75, min = 30, max = 250, step = .5),
          sliderInput("bw_tol", "Bodyweight matching window (± kg)", min = 1, max = 15, value = 5),
          checkboxInput("use_age", "Also match by age", FALSE),
          conditionalPanel(
            "input.use_age",
            numericInput("age", "Age (years)", 30, min = 14, max = 100),
            sliderInput("age_tol", "Age matching window (± years)", min = 1, max = 15, value = 5)
          ),
          numericInput("squat", "Best squat (kg)", 150, min = 1, step = 2.5),
          numericInput("bench", "Best bench press (kg)", 100, min = 1, step = 2.5),
          numericInput("deadlift", "Best deadlift (kg)", 180, min = 1, step = 2.5),
          actionButton("analyse", "Compare performance", class = "btn-primary w-100"),
          p(class = "control-note mt-3", "Tip: begin without age matching. Turn it on when the peer group is large enough.")
        ),
        uiOutput("state_message"),
        layout_columns(
          value_box(title = "Entered total", value = textOutput("total_value"),
                    showcase = "Σ", theme = "primary"),
          value_box(title = "Comparable performances", value = textOutput("peer_value"),
                    showcase = "≋", theme = "secondary"),
          value_box(title = "Potential priority", value = textOutput("weakest_value"),
                    showcase = "↗", theme = "warning"),
          col_widths = c(4, 4, 4)
        ),
        layout_columns(
          card(
            card_header("Percentile by lift"),
            p(class = "control-note", "A percentile is the share of comparable performances at or below your result. Higher is stronger relative to this peer group."),
            plotOutput("percentile_plot", height = 330)
          ),
          card(
            card_header("Total compared with peers"),
            p(class = "control-note", "The vertical line is your entered total; the bars show historical peer totals."),
            plotOutput("total_plot", height = 330)
          ),
          col_widths = c(6, 6)
        ),
        card(
          card_header("Detailed benchmark"),
          tableOutput("summary_table")
        ),
        p(class = "footer-note", "Interpretation: these are descriptive competition benchmarks, not causal evidence or a training programme. A person can appear in multiple meets, and records with incomplete lifts are excluded.")
      )
    )
  ),
  nav_panel(
    "Guide & limitations",
    div(
      class = "container py-4",
      card(
        card_header("How to use the benchmark"),
        card_body(
          tags$ol(
            tags$li("Choose the sex and equipment category used in the competition."),
            tags$li("Enter bodyweight and the three best successful lifts."),
            tags$li("Adjust the bodyweight window; optionally match on age."),
            tags$li("Select Compare performance, then read the percentile chart and peer distribution together.")
          ),
          h4("Fields"),
          p(strong("Raw"), "means no supportive suit or shirt; ", strong("Wraps"),
            "permits knee wraps; single-ply and multi-ply are equipped categories. Total is calculated as squat + bench press + deadlift."),
          h4("Interpret carefully"),
          tags$ul(
            tags$li("Rows are competition performances, not unique athletes; repeat competitors can influence the distribution."),
            tags$li("This is a historical snapshot and should not be read as a current ranking."),
            tags$li("Federations apply different rules and judging standards, which are not represented in this extract."),
            tags$li("A low relative percentile suggests an area to discuss with a qualified coach, not necessarily the lift that should receive more training.")
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  result <- eventReactive(input$analyse, {
    validate(
      need(is.numeric(input$bodyweight) && input$bodyweight > 0, "Enter a positive bodyweight."),
      need(all(c(input$squat, input$bench, input$deadlift) > 0), "All three lifts must be positive."),
      need(sum(c(input$squat, input$bench, input$deadlift)) <= 1500,
           "The entered total is outside a plausible range. Check the units and values.")
    )

    compare_lifter(
      powerlifting,
      sex = input$sex,
      equipment = input$equipment,
      bodyweight = input$bodyweight,
      squat = input$squat,
      bench = input$bench,
      deadlift = input$deadlift,
      age = if (isTRUE(input$use_age)) input$age else NULL,
      bodyweight_tolerance = input$bw_tol,
      age_tolerance = input$age_tol,
      min_n = 30
    )
  }, ignoreNULL = FALSE)

  output$state_message <- renderUI({
    x <- result()
    if (x$n == 0) {
      div(class = "weak-state mb-3", strong("No comparable performances."),
          " Broaden the bodyweight or age window, or check the selected category.")
    } else if (x$weak_sample) {
      div(class = "weak-state mb-3", strong("Small comparison group."),
          paste("Only", x$n, "records match. Broaden a matching window before drawing conclusions."))
    } else {
      div(class = "good-state mb-3", strong("A useful comparison group was found."),
          paste("Percentiles use", format(x$n, big.mark = ","), "matching performances."))
    }
  })

  output$total_value <- renderText({ paste0(sum(c(input$squat, input$bench, input$deadlift)), " kg") })
  output$peer_value <- renderText({ format(result()$n, big.mark = ",") })
  output$weakest_value <- renderText({
    if (result()$n == 0 || is.na(result()$weakest_lift)) "Not available" else result()$weakest_lift
  })

  output$percentile_plot <- renderPlot({
    x <- result()
    validate(need(x$n > 0, "No matching data to plot."))
    ggplot(x$summary, aes(x = reorder(lift, percentile), y = percentile, fill = lift)) +
      geom_col(width = .68, show.legend = FALSE) +
      geom_text(aes(label = paste0(percentile, "%")), hjust = -0.12, fontface = "bold") +
      coord_flip(clip = "off") +
      scale_y_continuous(limits = c(0, 108), breaks = seq(0, 100, 25), labels = function(z) paste0(z, "%")) +
      scale_fill_manual(values = c(Squat = "#315c6b", Bench = "#e08f3e", Deadlift = "#b33a3a", Total = "#6e5687")) +
      labs(x = NULL, y = "Percentile among matching performances") +
      theme_minimal(base_size = 12) +
      theme(panel.grid.major.y = element_blank(), plot.margin = margin(5.5, 30, 5.5, 5.5))
  })

  output$total_plot <- renderPlot({
    x <- result()
    validate(need(x$n > 0, "No matching data to plot."))
    entered_total <- x$summary$entered_kg[x$summary$lift == "Total"]
    ggplot(x$peers, aes(x = total_kg)) +
      geom_histogram(bins = 32, fill = "#8ba6af", colour = "white") +
      geom_vline(xintercept = entered_total, colour = "#b33a3a", linewidth = 1.2) +
      annotate("text", x = entered_total, y = Inf, label = "Your total", angle = 90,
               vjust = 1.4, hjust = 1.1, colour = "#8e2525", fontface = "bold") +
      labs(x = "Three-lift total (kg)", y = "Competition performances") +
      theme_minimal(base_size = 12)
  })

  output$summary_table <- renderTable({
    x <- result()
    validate(need(x$n > 0, "No matching performances. Change the filters to see a benchmark."))
    out <- x$summary
    names(out) <- c("Lift", "Your result (kg)", "Peer median (kg)", "Percentile")
    out$Percentile <- paste0(out$Percentile, "%")
    out
  }, striped = TRUE, hover = TRUE, bordered = FALSE, spacing = "m", digits = 1)
}

shinyApp(ui, server)
