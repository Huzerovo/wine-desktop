# Common functions

info() {
  printf "\033[;32m%s\033[0m\n" "$@"
}

warn() {
  printf "\033[;33m%s\033[0m\n" "$@"
}

erro() {
  printf "\033[;31m%s\033[0m\n" "$@" 1>&2
}

die() {
  erro "$@"
  exit 1
}

die_can_retry() {
  erro "$@"
  warn "you can rerun this script to continue installation after problem solved"
  exit 1
}
