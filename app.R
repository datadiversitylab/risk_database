library(shiny)
library(bslib)
library(DT)
library(dplyr)

df_preds <- read.csv("dataframes/processed/amphibians_final_predictions.csv")

if(! "prediction_date" %in% colnames(df_preds)) {
  df_preds$prediction_date <- "2026-03-04" 
}
if(! "model_version" %in% colnames(df_preds)) {
  df_preds$model_version <- "v1.0-alpha"
}

ui <- page_sidebar(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  title = "Global Extinction Risk Resource (Live Preview)",
  
  sidebar = sidebar(
    title = "Filters & Search",
    textInput("search_term", "Search by Scientific Name:", placeholder = "e.g., Atelopus..."),
    selectInput("status_filter", "Filter by Predicted Status:", 
                choices = c("All", "Threatened", "Not_Threatened")),
    hr(),
    downloadButton("download_data", "Download Dataset (CSV)")
  ),
  
  card(
    card_header("Provisional Results - Amphibians (Data Deficient)") ,
    p(style = "color: #d9534f; font-weight: bold;", 
      "DISCLAIMER: This is a provisional, machine learning-based estimate and does not replace an official IUCN assessment."),
    DTOutput("table_results")
  )
)

server <- function(input, output, session) {
  
  filtered_data <- reactive({
    data <- df_preds
    
    if (input$search_term != "") {
      data <- data %>% filter(grepl(input$search_term, binomial, ignore.case = TRUE))
    }
    
    if (input$status_filter != "All") {
      data <- data %>% filter(predicted_status == input$status_filter)
    }

    data %>% select(binomial, predicted_status, prob_threatened, prediction_date, model_version)
  })

  output$table_results <- renderDT({
    datatable(filtered_data(), options = list(pageLength = 10, scrollX = TRUE))
  })

  output$download_data <- downloadHandler(
    filename = function() {
      paste("amphibians_predictions_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      write.csv(df_preds, file, row.names = FALSE)
    }
  )
}

shinyApp(ui = ui, server = server)