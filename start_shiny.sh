#!/bin/bash
# script to start shiny app
R -q -e 'shiny::runApp("R/logdriver_shiny.R", port=8080, host = "0.0.0.0")'