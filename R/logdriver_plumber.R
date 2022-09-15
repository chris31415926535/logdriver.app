library(dplyr)
library(dbplyr)
library(DBI)
library(RSQLite)

#* Plot out data from the iris dataset
#* @get /append_log
append_log <- function(appname, user = NA, event = NA, description = NA, level = c("info", "warn", "error", "critical")){
  
  level <- match.arg(level, level)
  
  # make sure we use right directory. if we're testing, use project dir;
  # if we're running the API, use the project dir also! not R dir!
  if (interactive()) wd <- "./"
  if (!interactive()) wd <- "../"
  
  # if there is no log file yet, create one
  #if (!file.exists(paste0(wd,"logs/logs.sqlite"))) {}
  if (!dir.exists(paste0(wd, "logs"))) {
    dir.create(paste0(wd,"logs"))
  }
  
  
  # open SQLite connection, creating file if necessary
  connection <- RSQLite::dbConnect(RSQLite::SQLite(), paste0(wd, "logs/logs.sqlite"))
  
  # each app gets its own table in the database
  # get the existing table names, and add the current app name if it's not there
  table_names <- RSQLite::dbListTables(connection)
  
  if (!appname %in% table_names){
    empty_row <- dplyr::tribble(~datetime, ~level, ~user, ~event, ~description)
    RSQLite::dbCreateTable(connection, name = appname, empty_row)
  }
  
  
  
  # format the log entry
  log_entry <- dplyr::tibble(datetime = as.character(Sys.time(), tz = "UCT", usetz = TRUE),
                             level = level,
                             user = user,
                             event = event,
                             description = description)
  
  # add to the table
  #RSQLite::dbAppendTable(connection, appname, log_entry)
  db_logs <- dplyr::tbl(connection, appname)
  
  dplyr::rows_append(db_logs, log_entry, copy = TRUE, in_place = TRUE)
  
  #RSQLite::dbWriteTable()
  # logging for logs :)
  log_text <- sprintf("%s | %s | %s | %s | %s | %s", log_entry$datetime, level, appname, log_entry$user, log_entry$event, log_entry$description)
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
    dplyr::arrange(dplyr::desc(datetime)) %>%
    dplyr::collect() %>%
    return()
  
}


# create some test log data
# append_log("testapp", "you!", "read some logs", "have fun :)")
# append_log("testapp", "you!", "read some logs", "for persistent log storage, consider mounting an external volume to the container.")
# append_log("testapp", "you!", "read some logs", "so if you're running this in Docker, any new logs will disappear when your container is removed.")
# append_log("testapp", "you!", "read some logs", "it's stored in a SQLite file in the folder ./logs .")
# append_log("testapp", "you!", "read some logs", "this is the built-in test set of log data.")
# append_log("testapp", "you!", "got logdriver working!", "if you're seeing this, congratulations!")
# 
# get_logs("testapp")
