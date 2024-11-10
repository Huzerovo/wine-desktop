check_config_os() {
  if [[ -z "$CONFIG_OS" ]]; then
    die "Need set 'os' environment."
  fi

  case "$CONFIG_OS" in
    "debian" | "ubuntu") ;;

    *)
      die "Unknow os: '$CONFIG_OS', require 'debian' or 'ubuntu'."
      ;;
  esac
}
