#!/usr/bin/bash

source common.sh

user_exist() {
  grep -e "^$1:" /etc/passwd &> /dev/null
}

invalid_user() {
  if [[ "$1" == "$(echo "$1" | sed -n -E -r "/^[a-z][a-z0-9_-]{2,30}$/p")" ]]; then
    return 1
  fi
  return 0
}

choose_user() {
  info "Who will you run wine desktop as?"
  while read -r -p "(default '$PROOT_USER'): " username; do
    if [[ -z "$username" ]]; then
      info "Use default user: '$PROOT_USER'"
      break
    fi

    if invalid_user "$username"; then
      erro "Invalid user name '$username', require:"
      erro " 1. only cantains:"
      erro "    - small letters (a-z)"
      erro "    - numbers (0-9)"
      erro "    - short dash (-)"
      erro "    - underline (_)"
      erro " 2. start with small letter"
      continue
    fi

    if [[ "$username" != "root" ]]; then
      PROOT_USER="$username"
      PROOT_HOME="/home/$PROOT_USER"
      info "Use other user: '$PROOT_USER'"
    fi
    break
  done

  if user_exist "$PROOT_USER"; then
    info "User existd: '$PROOT_USER'"
  else
    shadowconfig on
    useradd -m -s "/bin/bash" "$PROOT_USER" \
      || {
        erro "Failed to create user"
        erro "Please relogin to start a new installation"
        exit 1
      }
    # set default password
    echo "$PROOT_USER:$PROOT_USER" | chpasswd

    info "Created user '$PROOT_USER'"
    warn "The default password is: '$PROOT_USER'"
  fi
}

create_wine_desktop() {
  if [[ -d "$PROOT_HOME" ]]; then
    # update old installation
    mkdir -p "$WINE_DESKTOP_CONTAINER"
    cp -rf "/var/cache/wine-desktop" "$(dirname "$WINE_DESKTOP_CONTAINER")"
    # chown "$PROOT_USER":"$PROOT_USER" -R "$PROOT_HOME"
    rm -rf "/var/cache/wine-desktop"
  else
    warn "User is created but can not find the home."
    warn "Please move '/var/cache/wine-desktop' to '$WINE_DESKTOP_CONTAINER' manually."
  fi
}

update_start_bin() {
  # config the start-wine-desktop
  local start_bin
  start_bin="/mnt/termux-home/.local/bin/start-wine-desktop"
  if [[ -w "$start_bin" ]]; then
    sed -i -E -r "/^PROOT_USER=.*$/c\PROOT_USER=\"$PROOT_USER\"" "$start_bin"
    sed -i -E -r "/^PROOT_HOME=.*$/c\PROOT_HOME=\"$PROOT_HOME\"" "$start_bin"
    sed -i -E -r "/^WINE_DESKTOP_CONTAINER=.*$/c\WINE_DESKTOP_CONTAINER=\"\$PROOT_HOME/.local/share/wine-desktop\"" "$start_bin"
  fi
}

os_update_mirrors() {
  local list="/etc/apt/sources.list"
  local listdeb822="/etc/apt/sources.list.d/ubuntu.sources"

  if [[ -f "$listdeb822" ]]; then
    if ! [[ -f "${listdeb822}.backup" ]]; then
      cp "$listdeb822" "${listdeb822}.backup"
    fi
    cat > "$listdeb822" << __EOF__
Types: deb
URIs: http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports
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
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-updates main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-backports main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ noble-security main restricted universe multiverse
__EOF__
  fi
}

update_mirrors() {
  # update and install essential packages
  info "Do you want to change the apt mirror?"
  warn "If you live in China, recommand yes."
  read -r -p "yes / no (default: yes): " input

  if [[ -n "$input" ]]; then
    info "Your chooson: '$input'"
    if [[ "${input^^}" == "YES" ]] || [[ "${input^^}" == "Y" ]]; then
      os_update_mirrors
    elif [[ "${input^^}" == "NO" ]] || [[ "${input^^}" == "N" ]]; then
      info "Use default apt source"
    fi
  else
    info "Use default option: 'yes'"
    os_update_mirrors
  fi
}

upgrade_packages() {
  info "Upgrading packages..."
  apt-get update -yqq
  apt-get upgrade -yqq
}

__grant_sudo_privilege() {
  mkdir -p /etc/sudoers.d/
  {
    echo "# Generate by wine-desktop"
    echo "# This file allow user '$PROOT_USER' use 'sudo' command"
    echo "$PROOT_USER   ALL=(ALL:ALL) ALL"
  } > /etc/sudoers.d/wine-desktop
  info "Granted user '$PROOT_USER' sudo privilege"
}

install_packages() {
  info "Installing 'sudo'..."
  apt-get install -yqq "sudo" &> /dev/null \
    || die_can_retry "Failed to install package 'sudo'"

  if ! [[ "$PROOT_USER" == "root" ]]; then
    __grant_sudo_privilege
  fi

  info "Installing others packages..."
  warn "Depending on your network, it may take a long time."
  local packages
  # TODO: remove 'dpkg-dev' and 'dh-cmake', they are required by building
  #       deb package for box64 and box86, but don't need now because they are
  #       installed by 'make install' now.
  # TODO: move 'gcc-arm-linux-gnueabihf' to wine-desktop-installer, install it
  #       when try to install box86
  case "$CONFIG_OS" in
    debian)
      packages=(
        "git"
        "wget"
        "cmake"
        "gcc-arm-linux-gnueabihf"
        "dpkg-dev"
        "dh-cmake"
      )
      ;;
    ubuntu)
      packages=(
        "git"
        "wget"
        "cmake"
        "gcc-arm-linux-gnueabihf"
        "dpkg-dev"
        "dh-cmake"
      )
      ;;
    *)
      die "Unsupport os: $CONFIG_OS"
      ;;
  esac
  apt-get install -yqq "${packages[@]}" &> /dev/null \
    || warn "Failed to install some required packages, but can ignore it."
}

install_installer_installation() {
  # install wine-desktop-installer next login
  cat > "/etc/profile.d/installer-installation.sh" <<- __EOF__
#!/usr/bin/bash

if [[ -n "\$WINE_DESKTOP_CONTAINER" ]]; then
  cd "\$WINE_DESKTOP_CONTAINER"
  bash "\$WINE_DESKTOP_CONTAINER/updater"
  # Do installation for install wine, winetricks, box
  # TODO: finish wine-desktop-installer for ubuntu and uncomment it
  # wine-desktop-installer --all
  sudo rm "/etc/profile.d/installer-installation.sh"
  printf "\033[;32m%s\033[0m\n" "OK, please use command 'start-wine-desktop' to relogin"
  exit 0
fi
__EOF__
}

main() {
  info "Welcome to login-installation."

  export PROOT_USER="root"
  export PROOT_HOME="/root"
  choose_user
  # NOTE: choose_user will change PROOT_USER and PROOT_HOME
  WINE_DESKTOP_CONTAINER="$PROOT_HOME/.local/share/wine-desktop"
  create_wine_desktop
  update_start_bin
  update_mirrors
  upgrade_packages
  install_packages
  install_installer_installation
  info "Everything is OK. =v="
  info "Use 'start-wine-desktop' to login"
  # remove self
  rm -f /etc/profile.d/login-installation.sh

  exit 0
}

main

# vim: ts=2 sts=2 sw=2
