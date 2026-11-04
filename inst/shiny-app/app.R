library(shiny)
library(bslib)
library(ggplot2)

# Data come from the installed package, not from an external file.
data("powerlifting", package = "bonafide", envir = environment())

min_peers <- 30
lift_colours <- c(Squat = "#315c6b", Bench = "#e08f3e",
                  Deadlift = "#b33a3a", Total = "#6e5687")

# One reusable plot theme so both charts look the same.
theme_bench <- function(base_size = 14) {
  theme_minimal(base_size = base_size) +
    theme(panel.grid.minor = element_blank(),
          axis.text.y = element_text(face = "bold"))
}

ui <- page_sidebar(
  title = "Powerlifting Peer Benchmarker",

  sidebar = sidebar(
    width = 300,
    selectInput("sex", "Competition sex", c("Women" = "F", "Men" = "M")),
    selectInput("equipment", "Equipment",
                c("Raw", "Wraps", "Single-ply", "Multi-ply")),
    numericInput("bodyweight", "Bodyweight (kg)", 75, min = 30, max = 250),
    sliderInput("bw_tol", "Bodyweight window (± kg)", min = 1, max = 15, value = 5),
    checkboxInput("use_age", "Also match by age", FALSE),
    conditionalPanel(
      "input.use_age",
      numericInput("age", "Age (years)", 30, min = 14, max = 100),
      sliderInput("age_tol", "Age window (± years)", min = 1, max = 15, value = 5)
    ),
    numericInput("squat", "Best squat (kg)", 150, min = 1),
    numericInput("bench", "Best bench press (kg)", 100, min = 1),
    numericInput("deadlift", "Best deadlift (kg)", 180, min = 1),
    p(class = "help",
      "Equipment: Raw = no supportive gear; Wraps = knee wraps; Single-/Multi-ply",
      "= supportive suits. The windows set how close a peer's bodyweight (and",
      "age) must be. Wider windows give more peers but a looser comparison.")
  ),

  tags$style("
    :root { --accent: #b33a3a; --ink: #1d2a32; --muted: #5c6970; }
    .intro { border-left: 6px solid var(--accent); padding-left: 1rem; }
    .intro strong { color: var(--accent); }
    .help { color: var(--muted); font-size: 0.85rem; }
    .status { padding: 0.6rem 1rem; border-left: 6px solid; margin: 0; }
    .status.good { border-color: #28735a; background: #e5f2ed; }
    .status.weak { border-color: #e0a800; background: #fff3cd; }
    .status.empty { border-color: var(--accent); background: #f8d7da; }
    .finding { font-size: 1.05rem; color: var(--ink); }
  "),

  card(
    class = "intro",
    p(strong("For: "), "competitive powerlifters and their coaches."),
    p(strong("Question: "), "compared with similar competitors, how strong is",
      "this performance, and which lift (squat, bench or deadlift) has the most",
      "room to improve?"),
    p(class = "help", "Choose who to compare against and enter the three best",
      "lifts on the left. Everything below updates automatically.")
  ),

  uiOutput("status"),

  layout_columns(
    col_widths = c(6, 6),
    card(
      card_header("Percentile by lift"),
      plotOutput("percentile_plot", height = 280),
      card_footer(class = "help",
                  "Percentile = % of peers at or below your lift. The dashed",
                  "line is the typical peer (50%). The shortest of the three",
                  "lift bars is the relative weak point.")
    ),
    card(
      card_header("Your total among peers"),
      plotOutput("total_plot", height = 280),
      card_footer(class = "help",
                  "Bars count peer totals. The red line is your total; the more",
                  "of the distribution to its left, the stronger the result.")
    )
  ),

  card(
    card_header("What this means"),
    textOutput("finding", container = p),
    tableOutput("summary_table"),
    card_footer(class = "help",
                "Limitations: rows are competition entries, not unique people,",
                "and the data are a historical snapshot (to 2019). These are",
                "descriptive benchmarks, not training advice.")
  )
)

server <- function(input, output, session) {

  # 1. Check the inputs and run the package function on the packaged data.
  result <- reactive({
    req(input$sex, input$equipment)
    validate(
      need(!is.na(input$bodyweight) && input$bodyweight >= 30 &&
             input$bodyweight <= 250, "Enter a bodyweight between 30 and 250 kg."),
      need(!is.na(input$squat) && input$squat > 0, "Enter a positive squat."),
      need(!is.na(input$bench) && input$bench > 0, "Enter a positive bench press."),
      need(!is.na(input$deadlift) && input$deadlift > 0, "Enter a positive deadlift."),
      need(!input$use_age || (!is.na(input$age) && input$age >= 14),
           "Enter an age of 14 or more, or untick age matching.")
    )
    validate(need(input$squat + input$bench + input$deadlift <= 1500,
                  "That total is above any recorded result. Check you used kg, not lb."))

    bonafide::compare_lifter(
      powerlifting,
      sex = input$sex, equipment = input$equipment,
      bodyweight = input$bodyweight, bodyweight_tolerance = input$bw_tol,
      age = if (input$use_age) input$age else NULL,
      age_tolerance = input$age_tol,
      squat = input$squat, bench = input$bench, deadlift = input$deadlift,
      min_n = min_peers
    )
  })

  # 2. Every output below reads result().
  output$status <- renderUI({
    x <- result()
    if (x$n == 0) {
      p(class = "status empty",
        "No comparable performances. Widen the bodyweight or age window,",
        "or untick age matching.")
    } else if (x$weak_sample) {
      p(class = "status weak",
        paste0("Only ", x$n, " peers match (fewer than ", min_peers, "). ",
               "Percentiles are unstable; widen a window before drawing conclusions."))
    } else {
      p(class = "status good",
        paste("Comparing with", format(x$n, big.mark = ","), "similar competition performances."))
    }
  })

  output$finding <- renderText({
    x <- result()
    validate(need(x$n > 0, "No peers to compare with yet."))
    lifts <- x$summary[1:3, ]
    paste0(
      "Your ", x$summary$entered_kg[4], " kg total equals or beats ",
      x$summary$percentile[4], "% of peers. Your strongest lift relative to peers is the ",
      tolower(lifts$lift[which.max(lifts$percentile)]), " (", max(lifts$percentile),
      "%) and your weakest is the ", tolower(x$weakest_lift), " (",
      min(lifts$percentile), "%), so the ", tolower(x$weakest_lift),
      " has the most room to improve."
    )
  })

  output$percentile_plot <- renderPlot({
    x <- result()
    validate(need(x$n > 0, "No matching peers to plot."))
    d <- x$summary
    d$lift <- factor(d$lift, levels = rev(d$lift))
    ggplot(d, aes(x = lift, y = percentile, fill = lift)) +
      geom_col(width = 0.65) +
      geom_hline(yintercept = 50, linetype = "dashed") +
      geom_text(aes(label = paste0(percentile, "%")), hjust = -0.15) +
      scale_fill_manual(values = lift_colours, guide = "none") +
      scale_y_continuous(limits = c(0, 110), breaks = seq(0, 100, 25)) +
      coord_flip() +
      labs(x = NULL, y = "Percentile among peers (%)") +
      theme_bench()
  })

  output$total_plot <- renderPlot({
    x <- result()
    validate(need(x$n > 0, "No matching peers to plot."))
    ggplot(x$peers, aes(x = total_kg)) +
      geom_histogram(bins = 30, fill = "grey75", colour = "white") +
      geom_vline(xintercept = x$summary$entered_kg[4], colour = "#b33a3a",
                 linewidth = 1.3) +
      labs(x = "Three-lift total (kg)", y = "Peers") +
      theme_bench()
  })

  output$summary_table <- renderTable({
    x <- result()
    req(x$n > 0)
    out <- x$summary
    names(out) <- c("Lift", "Yours (kg)", "Peer median (kg)", "Percentile (%)")
    out
  }, digits = 1)
}

shinyApp(ui, server)
