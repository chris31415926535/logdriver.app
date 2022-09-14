#!/bin/bash
# script to start plumber
R -q -e 'plumber::pr_run(plumber::pr("R/logdriver_plumber.R"), port=8000, host = "0.0.0.0")'