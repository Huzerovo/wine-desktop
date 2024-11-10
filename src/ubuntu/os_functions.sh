os_update_mirrors() {
  local list="/etc/apt/sources.list"
  if ! [[ -f "${list}.backup" ]]; then
    cp "$list" "${list}.backup"
  fi
  cat > "$list" << __EOF__
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
__EOF__

  local listdeb822="/etc/apt/sources.list.d/ubuntu.sources"
  if ! [[ -f "${listdeb822}.backup" ]]; then
    cp "$listdeb822" "${listdeb822}.backup"
  fi
  cat > "$listdeb822" <<__EOF__
Types: deb
URIs: http://mirrors.tuna.tsinghua.edu.cn/ubuntu
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# 以下安全更新软件源包含了官方源与镜像站配置，如有需要可自行修改注释切换
Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
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
