#!/usr/bin/bash

# DO NOT use '*'
# Add all files one by one in full name
SOURCE_FILES=(
  "start-wine-desktop"
  "install.sh"
  "login-installation.sh"
)
# output all source command into a single file

builder() {
  if [[ -f "$2" ]]; then
    mv "$2" "${2}.bak"
  fi

  regex='^(\s*)source\s+"?([^[:space:]"]+)"?\s*$'

  local ifs_old="$IFS"
  IFS=$'\n'

  local src_dirname
  src_dirname="$(dirname "$1")"

  while read -r out_line; do
    source_file=$(echo "$out_line" | sed -n -E -r "s/$regex/\2/p")
    local prefix="$src_dirname"
    if [[ -n "$source_file" ]]; then
      source_file="$(eval echo "$source_file")"
      if [[ -f "$prefix/$source_file" ]]; then
        local indent
        indent="$(echo "$out_line" | sed -n -E -r "s/$regex/\1/p")"
        while read -r sourced_line; do
          echo "${indent}${sourced_line}" >> "$2"
        done < "$prefix/$source_file"
      else
        echo "No this source file: '$prefix/$source_file', ignore"
        echo "$out_line" >> "$2"
      fi
    else
      echo "$out_line" >> "$2"
    fi
  done < "$1"

  IFS="$ifs_old"

  if [[ -f "${2}.bak" ]]; then
    rm -f "${2}.bak"
  fi
}

usage() {
  cat << __EOF__
Usage: build [OPTIONS]

Options:
  --all         Build all files
  --clean       Clean build files
  --help, -h    Show this help
__EOF__
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

case $1 in
  --help | -h)
    usage
    exit 0
    ;;
  --all)
    for file in "${SOURCE_FILES[@]}"; do
      builder "src/${file}" "${file}"
    done
    ;;
  --clean)
    for file in "${SOURCE_FILES[@]}"; do
      rm -f "$PWD/$file"
    done
    ;;
  *)
    usage
    exit 1
    ;;
esac

# vim: ts=2 sts=2 sw=2
