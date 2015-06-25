#!/bin/bash

#
# Utility Functions
#

function UtilToUpper() {
  awk '{print toupper($0)}' <<<"$@"
}

function UtilToLower() {
  awk '{print tolower($0)}' <<<"$@"
}

function UtilConstantize() {
  UtilToUpper "$@" | sed 's/[^A-Z]+/_/g' | UtilToLower
}

function UtilDasherize() {
  UtilToUpper "$@" | sed 's/[^A-Z]+/-/g' | UtilToLower
}

function UtilCountLines() {
  wc -l <<<"$1"
}
