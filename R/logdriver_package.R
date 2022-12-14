
add_log <- function(level = c("info", "warn", "error", "critical"), username = NA, event = NA, description = NA, logdriver_appname = NA, logdriver_host = NA, logdriver_port = NA, logdriver_apikey = NA){

  logdriver_host <- check_env("LOGDRIVER_HOST", logdriver_host)
  logdriver_port <- check_env("LOGDRIVER_PORT", logdriver_port)
  logdriver_appname <- check_env("LOGDRIVER_APPNAME", logdriver_appname)
  logdriver_apikey <- check_env("LOGDRIVER_APIKEY", logdriver_apikey, okay_to_have_neither = TRUE)

  # FIXMETODO ensure that appname works okay because we use it to createa sql table later

  # ensure we have values from environment or function parameters
  # we don't handle apikey since not all apps will use one
  if (is.na(logdriver_host)) stop ("Please set environment variable LOGDRIVER_HOST or provide function parameter logdriver_host.")
  if (is.na(logdriver_port)) stop ("Please set environment variable LOGDRIVER_PORT or provide function parameter logdriver_port.")
  if (is.na(logdriver_appname)) stop ("Please set environment variable LOGDRIVER_APPNAME or provide function parameter logdriver_appname.")

  level <- match.arg(level, level)

  # get date and time in Greenwich Mean Time / UTC
  # NOTE! this is now done on the server
  #datetime <- as.POSIXlt(Sys.time(), tz = "GMT")

  # set base url
  base_url <- sprintf("https://%s:%s/append_log", logdriver_host, logdriver_port)

  # create HTTP GET request
  req <- httr2::request(base_url)

  # add parameters
  req <- req %>%
    httr2::req_url_query(
      `appname` = logdriver_appname,
      `level` = level,
      `user` = username,
      `event` = event,
      `description` = description
    )

  # resp <- req %>%
  #   httr2::req_perform()

  resp <- req %>%
    httr2::req_error(is_error = function(resp) FALSE) %>%
    httr2::req_perform()

  #httr2::resp_body_json(resp)

  logdriver_respcode <- httr2::resp_status(resp)
  logdriver_respbody <- unlist(httr2::resp_body_json(resp))

  if (logdriver_respcode != 200) {
    logmessage <- sprintf("%s | %s | %s | %s | %s ||| %s" , Sys.time(), level, username, event, description, logdriver_respbody)
    message(logmessage)
  }

  if (httr2::resp_status(resp) == 200) {
    logmessage <- logdriver_respbody
    message(logmessage)
  }

}


# Check to see if we're using environment variable or function variable
# Function variable overrides environment variable
check_env <- function(env_varname, function_var, okay_to_have_neither = FALSE){

  # get the variable names and values for our environment and function parameters
  function_varname <- deparse(substitute(function_var))

  function_val <- function_var

  env_val <- Sys.getenv(env_varname)

  # use environment value by default
  val_to_use <- env_val

  # handle various options
  if (env_val == "" & is.na(function_val) & !okay_to_have_neither) {
    stop(sprintf("Please provide a valid parameter %s or set the environment variable %s.", function_varname, env_varname))
  }

  if (!is.na(function_val))  {
    if (env_val != "") warning(sprintf("Function variable %s='%s' overrides environment parameter %s='%s'.",
                                       function_varname,
                                       function_val,
                                       env_varname,
                                       env_val))
    val_to_use <- function_val
  }

  return(val_to_use)

}

add_log(username = "gollum", event = "saw ring", description = "wowwwwwwwwwww")

add_log(logdriver_host = "asdf", logdriver_port = "asdf")

logdriver_host <- NA
check_env("asd", logdriver_host)
check_env("BUTTS" , logdriveR_ho)

Sys.setenv("LOGDRIVER_HOST" = "0.0.0.0")
Sys.setenv("LOGDRIVER_HOST" = "logdriver-test.fly.dev")
Sys.setenv("LOGDRIVER_PORT" = "8000")

Sys.setenv("LOGDRIVER_APPNAME" = "test")
Sys.setenv("LOGDRIVER_HOST" = "")
Sys.setenv("LOGDRIVER_PORT" = "")

Sys.getenv("LOGDRIVER_HOST")
Sys.getenv("LOGDRIVER_PORT")

test("asdf")
