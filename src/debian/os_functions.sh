os_update_mirrors() {
  cp "/etc/apt/sources.list" "/etc/apt/sources.list.backup"
  sed -i -E -r 's/deb\.debian\.org/mirrors\.tuna\.tsinghua\.edu\.cn/' "/etc/apt/sources.list"
}

os_upgrade_packages() {
  apt-get update -yqq
  apt-get upgrade -yqq
}

os_install_packages() {
  for pkg in "$@"; do
    apt-get install -yqq "$pkg"
  done
}

# vim: ts=2 sts=2 sw=2
