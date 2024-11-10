os_update_mirrors() {
  local list="/etc/apt/sources.list"
  local listdeb822="/etc/apt/sources.list.d/ubuntu.sources"

  if [[ -f "$listdeb822" ]]; then
    if ! [[ -f "${listdeb822}.backup" ]]; then
      cp "$listdeb822" "${listdeb822}.backup"
    fi
    cat > "$listdeb822" << __EOF__
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
__EOF__
  else
    if ! [[ -f "${list}.backup" ]]; then
      cp "$list" "${list}.backup"
    fi
    cat > "$list" << __EOF__
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-backports main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ noble-security main restricted universe multiverse
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
