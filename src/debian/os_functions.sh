os_update_mirrors() {
  apt-get update &> /dev/null
  apt-get install -yqq apt-transport-https ca-certificates &> /dev/null
  cp "/etc/apt/sources.list" "/etc/apt/sources.list.backup"
  cat > "/etc/apt/sources.list" << __EOF__
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
deb https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
__EOF__
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
