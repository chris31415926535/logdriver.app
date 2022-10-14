# Basic shiny app for viewing logs stored in a SQLite database inthe ./logs folder
# PERHAPS this could be a docker volume or a local file
# works with ./R/logdriver_plumber.R which receives log updates

# FIXME!! TODO!!!
# perhaps get logs from logdr

library(shiny)
#library(shinydashboard)
#library(shinydashboardPlus)
library(dplyr)
library(dbplyr)
library(DBI)
library(RSQLite)
library(DT)
library(plotly)
library(plumber)
library(lubridate)

app_version <- "0.0.1.9000"

ui <- shiny::navbarPage(
  title = paste0("Logdriver v", app_version),
  shiny::tabPanel(title = "Analysis",
                  
                  shiny::sidebarLayout(
                    shiny::sidebarPanel(
                      width = 2,
                      
                      selectInput("select_table",
                                  "Application",
                                  choices = "Loading..")
                      
                      ,selectInput("select_timeunit",
                                   "Time Unit",
                                   choices = c("Seconds" = "sec",
                                               "Minutes" = "min",
                                               "15 Minutes" = "15 min",
                                               "Hours" = "hour",
                                               "Days" = "day",
                                               "Weeks" = "week",
                                               "Months" = "month",
                                               "Years" = "year"))
                      
                    )
                    ,
                    
                    shiny::mainPanel(
                      width = 10,
                      
                      fluidRow(#title = "plot over time!",
                        width = 12,
                        height="430px",
                        plotly::plotlyOutput("log_plot")),
                      fluidRow(title = "Log Details",
                               width = 12,
                               DT::dataTableOutput("log_table")
                      )
                    )
                  )
  )
  
  ,tabPanel(title = "Admin",
            shiny::fluidRow(h1("Delete User Logs"),
                            shiny::selectInput("select_deleteuserlogs_app",
                                               "Application",
                                               choices = "Loading..."),
                            shiny::textInput("select_deleteuserlogs_user",
                                             "User"),
                            shiny::actionButton("button_deleteuserlogs",
                                                label = "Delete User Logs")),
            shiny::fluidRow(h1("Delete Application Logs"),
                            shiny::selectInput("select_deletelogs",
                                               "Application Log to Delete",
                                               choices = "Loading...")),
            
            shiny::actionButton("button_deletelogs",
                                label = "Delete Application Logs")
            
  )
  
  ,tabPanel(title = "About",
            p("This is the jankiest work in progress imaginable. It has basic functionality I need for now."),
            p("I'm going to update it as I need to..."))
  
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
  
  updateSelectInput(inputId = "select_deletelogs",
                    choices = table_names)
  
  updateSelectInput(inputId = "select_deleteuserlogs_app",
                    choices = table_names)
  
  log_data <- reactiveValues(unfiltered = dplyr::tibble(),
                             filtered = dplyr::tibble())
  
  
  update_logs_timer <- reactiveTimer(5000)
  
  # A MESS!! Two ways to update!! Need better reactive graph!!!
  observeEvent(update_logs_timer(),
               {
                 req(input$select_table)
                 if (!is.null(input$select_table) & input$select_table != "" & input$select_table != "Loading.." & input$select_table != "No logs found"){
                   
                   message("updating table every 5 seconds")
                   log_data$unfiltered <- dplyr::tbl(connection, input$select_table) %>%
                     dplyr::arrange(dplyr::desc(datetime)) %>%
                     dplyr::collect() %>%
                     dplyr::mutate(datetime = lubridate::as_datetime(datetime)) #, tz = "UCT")) #%>% lubridate::with_tz(input$select_timezone))
                   
                   log_data$filtered <- log_data$unfiltered
                 }
                 
                 
                 if (input$select_table == "No logs found"){
                   log_data$unfiltered <- log_data$filtered <- dplyr::tibble()
                 }
                 
               }
  )
  
  observeEvent(input$select_table, 
               {
                 req(input$select_table)
                 message("updating table: user change")
                 
                 if (input$select_table == "No logs found"){
                   log_data$unfiltered <- log_data$filtered <- dplyr::tibble()
                 } else {
                   
                   log_data$unfiltered <- dplyr::tbl(connection, input$select_table) %>%
                     dplyr::arrange(dplyr::desc(datetime)) %>%
                     dplyr::collect() %>%
                     dplyr::mutate(datetime = lubridate::as_datetime(datetime)) #, tz = "UCT")) #%>% lubridate::with_tz(input$select_timezone))
                   log_data$filtered <- log_data$unfiltered
                 }
                 
               },
               ignoreNULL = TRUE,
               ignoreInit = TRUE
  )
  
  
  
  
  output$log_plot <- plotly::renderPlotly({
    #
    req(input$select_timeunit)
    timerange <- max(log_data$filtered$datetime) - min(log_data$filtered$datetime)
    theplot <- ggplot2::ggplot()
    
    if (is.finite(timerange)) {
      
      timeunit <- tolower(input$select_timeunit)#"15 minutes"
      
      # timeunit <- "15 minutes"
      
      forplot <-  log_data$filtered %>%
        dplyr::mutate(datetime_floor = lubridate::floor_date(datetime, unit = timeunit)) %>%
        dplyr::group_by(datetime_floor) %>%
        dplyr::count()
      
      theplot <- ggplot2::ggplot(data = forplot,
                                 mapping = ggplot2::aes(x=datetime_floor, y = n)) +
        ggplot2::geom_col() + #width = 0.9, fill = "#123456") +
        # ggplot2::scale_x_datetime(date_breaks = timeunit) +
        ggplot2::theme_minimal()
      
    } # end if is finite timerange
    
    plotly::ggplotly(theplot)
  })
  
  output$log_table <- DT::renderDataTable({
    req(log_data$filtered)
    
    if (nrow(log_data$filtered) > 0) {
      DT::datatable(log_data$filtered, 
                    options = list(dom = "tfp"),
                    rownames = FALSE) %>%
        DT::formatStyle(columns = 1:ncol(log_data$filtered), fontSize = '80%', lineHeight='70%')
    } else {
      dplyr::tibble()
    }
  }
  )
  
  
  
  # Show modal when user says they want to delete an application log
  observeEvent(input$button_deletelogs, {
    message("clicked delete button")
    
    appname_to_delete <- input$select_deletelogs
    
    shiny::showModal(
      shiny::modalDialog(title = "Really delete logs??",
                         p(sprintf("This will PERMANENTLY delete the logs for the application %s.", appname_to_delete)),
                         p("Are you sure you want to do this?"),
                         footer = tagList(
                           modalButton("No, I really don't"),
                           actionButton("button_deletelogs_confirm", "Yes, I really do")
                         )
      )
    )
    
  })
  
  # If they click they want to delete the logs for sure, do it
  # then re-update the select inputs so that nothing is messed up
  # NOTE! This is messy and should be done in a function since it's repeated
  observeEvent(input$button_deletelogs_confirm,{
    appname_to_delete <- input$select_deletelogs
    
    message(sprintf("Deleting log for app %s", appname_to_delete))
    
    DBI::dbRemoveTable(conn = connection, appname_to_delete)
    
    # each app gets its own table in the database
    # get the existing table names, and add the current app name if it's not there
    table_names <- RSQLite::dbListTables(connection)
    
    message(table_names)
    
    if (length(table_names) > 0){
      updateSelectInput(inputId = "select_table",
                        choices = table_names,
                        selected = table_names[[1]])
    } else {
      updateSelectInput(inputId = "select_table",
                        choices = "No logs found",
                        selected = "No logs found")
    }
    
    updateSelectInput(inputId = "select_deletelogs",
                      choices = table_names)
    
    message(input$select_table)
    
    log_data <- reactiveValues(unfiltered = dplyr::tibble(),
                               filtered = dplyr::tibble())
    
    shiny::removeModal()
    
  }
  )
  
  # DELETE USER LOGS WITHIN AN APPLICATION
  # Show modal when user says they want to delete USER application log
  observeEvent(input$button_deleteuserlogs, {
    message("clicked delete user logs button")
    
    appname_to_delete <- input$select_deleteuserlogs_app
    username_to_delete <- input$select_deleteuserlogs_user
    
    shiny::showModal(
      shiny::modalDialog(title = "Really delete user logs??",
                         p(sprintf("This will PERMANENTLY delete the logs for username %s the application %s.", username_to_delete, appname_to_delete)),
                         p("Are you sure you want to do this?"),
                         footer = tagList(
                           modalButton("No, I really don't"),
                           actionButton("button_deleteuserlogs_confirm", "Yes, I really do")
                         )
      )
    )
    
  })
  
  # If they click they want to delete the logs for sure, do it
  # then re-update the select inputs so that nothing is messed up
  # NOTE! This is messy and should be done in a function since it's repeated
  observeEvent(input$button_deleteuserlogs_confirm,{
    appname_to_delete <- input$select_deleteuserlogs_app
    username_to_delete <- input$select_deleteuserlogs_user
    
    
    message(sprintf("Deleting log for user %s for app %s", username_to_delete, appname_to_delete))
    
    
    
    # LOGIC TO DELETE USER LOGS GOESHERE
    # generate SQL command by creating a SELECT command and replacing it with DELETE
    # could be done with raw SQL, should just have form  "DELETE \nFROM `deleteme`\nWHERE (`user` = 'chris')"
    # because the query is very simple
    
    # https://stackoverflow.com/questions/70395226/dbplyr-delete-row-from-a-table-in-database
    
    logfile <- dplyr::tbl(connection, appname_to_delete)
    
    logs_to_delete <- dplyr::filter(logfile, user == username_to_delete)
    
    # FIXME TODO! Should do basic SQL injection check here! In the meantime
    # though this is already on the admin page so likely no extra risk..
    query <- dbplyr::sql_render(logs_to_delete) %>%
      as.character() %>%
      gsub(pattern = "SELECT *", replacement = "DELETE ", fixed = TRUE)
    
    DBI::dbExecute(connection, query)
    
    log_data <- reactiveValues(unfiltered = dplyr::tibble(),
                               filtered = dplyr::tibble())
    
    shiny::removeModal()
    
  }
  )
  
}

shinyApp(ui, server)
