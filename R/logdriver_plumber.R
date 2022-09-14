library(dplyr)
library(dbplyr)
library(DBI)
library(RSQLite)

#* Plot out data from the iris dataset
#* @get /append_log
append_log <- function(appname, user = NA, event = NA, description = NA){
  
  # make sure we use right directory. if we're testing, use project dir;
  # if we're running the API, use the project dir also! not R dir!
  if (interactive()) wd <- "./"
  if (!interactive()) wd <- "../"
  
  # if there is no log file yet, create one
  if (!file.exists(paste0(wd,"logs/logs.sqlite"))) {
    dir.create(paste0(wd,"logs"))
  }
  
  # open SQLite connection, creating file if necessary
  connection <- RSQLite::dbConnect(RSQLite::SQLite(), paste0(wd, "logs/logs.sqlite"))
  
  # each app gets its own table in the database
  # get the existing table names, and add the current app name if it's not there
  table_names <- RSQLite::dbListTables(connection)
  
  if (!appname %in% table_names){
    empty_row <- dplyr::tribble(~datetime, ~user, ~event, ~description)
    RSQLite::dbCreateTable(connection, name = appname, empty_row)
  }
  
  
  
  # format the log entry
  log_entry <- dplyr::tibble(datetime = as.character(Sys.time(), tz = "UCT", usetz = TRUE),
                             user = user,
                             event = event,
                             description = description)
  
  # add to the table
  #RSQLite::dbAppendTable(connection, appname, log_entry)
  db_logs <- dplyr::tbl(connection, appname)
  
  dplyr::rows_append(db_logs, log_entry, copy = TRUE, in_place = TRUE)
  
  #RSQLite::dbWriteTable()
  # logging for logs :)
  log_text <- sprintf("%s | %s | %s | %s | %s", log_entry$datetime, appname, log_entry$user, log_entry$event, log_entry$description)
  message(log_text)
  
  # disconnect
  RSQLite::dbDisconnect(connection)
  
  return(log_text)
}




#* Get all logs. this is for testing
#* @get /get_logs
get_logs <- function(appname){

  # make sure we use right directory. if we're testing, use project dir;
  # if we're running the API, use the project dir also! not R dir!
  if (interactive()) wd <- "./"
  if (!interactive()) wd <- "../"
  
  
  # if there is no log file yet, create one
  if (!file.exists(paste0(wd, "logs/logs.sqlite"))) {
    stop("No logs found.")
  }
  
  # open SQLite connection, creating file if necessary
  connection <- RSQLite::dbConnect(RSQLite::SQLite(), paste0(wd,"logs/logs.sqlite"))
  
  # each app gets its own table in the database
  # get the existing table names, and add the current app name if it's not there
  table_names <- RSQLite::dbListTables(connection)
  
  if (!appname %in% table_names){
    stop(paste0("No logs for app ", appname))
  }
  
  
  db_logs <- dplyr::tbl(connection, appname)
  
  db_logs %>%
    dplyr::collect() %>%
    return()
  
}
