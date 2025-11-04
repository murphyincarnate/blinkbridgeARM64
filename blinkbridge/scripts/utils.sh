#!/bin/bash

# Define color codes
COLOR_RED=$(tput setaf 1)
COLOR_GREEN=$(tput setaf 2)
COLOR_YELLOW=$(tput setaf 3)
COLOR_BLUE=$(tput setaf 4)
COLOR_BOLD=$(tput bold)
COLOR_RESET=$(tput sgr0)

# Initialize log level variable
LOG_LEVEL="debug"

# Function to set log level
set_log_level() {
  case "$1" in
    debug|info|warn|error)
      export LOG_LEVEL="$1"
      ;;
    *)
      echo "${COLOR_BOLD}${COLOR_RED}Invalid log level: ${1}${COLOR_RESET}"
      ;;
  esac
}

# Function to print debug messages in green
debug() {
  if [[ "$LOG_LEVEL" == "debug" ]]; then
    echo "${COLOR_BOLD}${COLOR_GREEN}debug${COLOR_RESET}: $@"
  fi
}

# Function to print informational messages in blue
info() {
  if [[ "$LOG_LEVEL" == "debug" || "$LOG_LEVEL" == "info" ]]; then
    echo "${COLOR_BOLD}${COLOR_BLUE}info${COLOR_RESET}: $@"
  fi
}

# Function to print warning messages in yellow
warn() {
  if [[ "$LOG_LEVEL" == "debug" || "$LOG_LEVEL" == "info" || "$LOG_LEVEL" == "warn" ]]; then
    echo "${COLOR_BOLD}${COLOR_YELLOW}warn${COLOR_RESET}: $@"
  fi
}

# Function to print error messages in red
error() {
  echo "${COLOR_BOLD}${COLOR_RED}error${COLOR_RESET}: $@"
}
