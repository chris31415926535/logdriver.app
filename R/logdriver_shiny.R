# Basic shiny app for viewing logs stored in a SQLite database inthe ./logs folder
# PERHAPS this could be a docker volume or a local file
# works with ./R/logdriver_plumber.R which receives log updates

# FIXME!! TODO!!!
# perhaps get logs from logdr

library(shiny)
library(dplyr)
library(dbplyr)
library(DBI)
library(RSQLite)
library(DT)
library(plotly)
library(plumber)
library(lubridate)

ui <- fluidPage(
  sidebarLayout(
    sidebarPanel = sidebarPanel(p("asdf"),
                                selectInput("select_table",
                                            "Application",
                                            choices = "Loading..")
                                
                                ,selectInput("select_timerange",
                                             "Time Range",
                                             choices = c("Hour",
                                                         "Day",
                                                         "Week",
                                                         "Month",
                                                         "Year"))
                                # selectInput("select_timezone",
                                # "Time Zone",
                                # choices = c("America/Toronto", "UCT")),
    ),
    
    mainPanel = mainPanel(fluidRow(p("plot over time!"),
                                   plotly::plotlyOutput("log_plot")),
                          fluidRow(
                            DT::dataTableOutput("log_table")
                          ))
  )
)

server <- function(input, output, session) {
  
  # make sure we use right directory. if we're testing, use project dir;
  # if we're running the API, use the project dir also! not R dir!
  # if (interactive()) wd <- "./"
  #if (!interactive()) wd <- "../"
  wd <- "../"
  
  # if there is no log file yet, create one
  if (!file.exists(paste0(wd,"logs/logs.sqlite"))) {
    dir.create(paste0(wd,"logs"))
  }
  
  # open SQLite connection, creating file if necessary
  connection <- RSQLite::dbConnect(RSQLite::SQLite(), paste0(wd, "logs/logs.sqlite"))
  
  # each app gets its own table in the database
  # get the existing table names, and add the current app name if it's not there
  table_names <- RSQLite::dbListTables(connection)
  
  updateSelectInput(inputId = "select_table",
                    choices = table_names)
  
  log_data <- reactiveValues(unfiltered = dplyr::tibble(),
                             filtered = dplyr::tibble())
  
  
  update_logs_timer <- reactiveTimer(5000)
  
  # A MESS!! Two ways to update!! Need better reactive graph!!!
  observeEvent(update_logs_timer(),
               {
                 
                 if (!is.null(input$select_table) & input$select_table != "Loading.."){
                   
                   message("updating table every 5 seconds")
                   log_data$unfiltered <- dplyr::tbl(connection, input$select_table) %>%
                     dplyr::collect() %>%
                     dplyr::mutate(datetime = lubridate::as_datetime(datetime)) #, tz = "UCT")) #%>% lubridate::with_tz(input$select_timezone))
                   
                   log_data$filtered <- log_data$unfiltered
                 }
               }
  )
  
  observeEvent(input$select_table, 
               {
                 
                 message("updating table: user change")
                 log_data$unfiltered <- dplyr::tbl(connection, input$select_table) %>%
                   dplyr::collect() %>%
                   dplyr::mutate(datetime = lubridate::as_datetime(datetime)) #, tz = "UCT")) #%>% lubridate::with_tz(input$select_timezone))
                 log_data$filtered <- log_data$unfiltered
               },
               ignoreNULL = TRUE,
               ignoreInit = TRUE
  )
  
  
  
  
  output$log_plot <- plotly::renderPlotly({
    #
    timerange <- max(log_data$filtered$datetime) - min(log_data$filtered$datetime)
    theplot <- ggplot2::ggplot()
    
    if (is.finite(timerange)) {
      
      timeunit <- "15 minutes"
      forplot <-  log_data$filtered %>%
        dplyr::mutate(datetime_floor = lubridate::floor_date(datetime, unit = timeunit)) %>%
        dplyr::group_by(datetime_floor) %>%
        dplyr::count()
      
      theplot <- ggplot2::ggplot(data = forplot,
                                 mapping = ggplot2::aes(x=datetime_floor, y = n)) +
        ggplot2::geom_col()
      
    } # end if is finite timerange
    
    plotly::ggplotly(theplot)
  })
  
  output$log_table <- DT::renderDataTable({
    log_data$filtered
    
    
  })
}

shinyApp(ui, server)