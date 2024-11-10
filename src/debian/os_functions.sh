os_update_mirrors() {
  local list="/etc/apt/sources.list"
  local listdeb822="/etc/apt/sources.list.d/debian.sources"
  if [[ -f "$listdeb822" ]]; then
    if ! [[ -f "${listdeb822}.backup" ]]; then
      cp "$listdeb822" "${listdeb822}.backup"
    fi
    cat > "$listdeb822" << __EOF__
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/debian
Suites: bookworm bookworm-updates bookworm-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://security.debian.org/debian-security
Suites: bookworm-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
__EOF__
  else
    if ! [[ -f "${list}.backup" ]]; then
      cp "$list" "${list}.backup"
    fi
    cat > "$list" << __EOF__
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
deb https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
__EOF__

  fi
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
