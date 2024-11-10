os_update_mirrors() {
  # Replace http://ports.ubuntu.com/ubuntu-ports
  cp "/etc/apt/sources.list" "/etc/apt/sources.list.backup"
  sed -i -E -r 's/(http|https):\/\/ports\.ubuntu\.com\/ubuntu-ports/https:\/\/mirrors\.tuna\.tsinghua\.edu\.cn\/ubuntu/' "/etc/apt/sources.list"
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
