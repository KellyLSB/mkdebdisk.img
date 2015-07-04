#!/bin/bash

function __GrubEtcDefaultVar() {
  sed -Ei "s/^($1)=\"(.+)\"\$/\1=\"$2\"/" "$3"
}

function __GrubHasEtcDefaultVar() {
  grep -Eq "^($1)=\"(.+)\"\$" "$2"
}

function GrubAppendEtcDefaultVar() {
  local var="$(UtilToUpper "$1")" val="$2" file="/etc/default/grub"

  if __GrubHasEtcDefaultVar "${var}" "${val}"; then
    __GrubEtcDefaultVar "${var}" "\2 ${val}" "${file}"
  else
    echo "${var}=\"${val}\"" >> "${file}"
  fi
}

function GrubSetEtcDefaultVar() {
  local var="$(UtilToUpper "$1")" val="$2" file="/etc/default/grub"

  if __GrubHasEtcDefaultVar "${var}" "${file}"; then
    __GrubEtcDefaultVar "${var}" "${val}" "${file}"
  else
    echo "${var}=\"${val}\"" >> "${file}"
  fi
}
