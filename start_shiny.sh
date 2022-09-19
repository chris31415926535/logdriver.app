#!/bin/bash
# script to start shiny app
# running navbar version right now
R -q -e 'shiny::runApp("R/logdriver_shiny_nav.R", port=8080, host = "0.0.0.0")'