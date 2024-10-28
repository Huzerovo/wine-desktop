#!/usr/bin/bash

info() {
  printf "\033[;32m%s\033[0m\n" "$@"
}

warn() {
  printf "\033[;33m%s\033[0m\n" "$@"
}

erro() {
  printf "\033[;31m%s\033[0m\n" "$@" 1>&2
}

die_can_rerun() {
  erro "$@"
  warn "you can rerun this script to continue by relogin"
  warn "login command: 'proot-distro login debian'"
  exit 1
}

info "Welcome to pacages-installation"

# update and install essential packages
info "Do you want to change the apt mirror?"
warn "If you live in China, recommand yes."
read -r -p "yes / no (default: yes): " input
if [[ -n "$input" ]]; then
  info "Your chooson: '$input'"
  if [[ "${input^^}" == "YES" ]] || [[ "${input^^}" == "Y" ]]; then
    sed -i -E -r 's/deb\.debian\.org/mirrors\.tuna\.tsinghua\.edu\.cn/' "/etc/apt/sources.list"
  elif [[ "${input^^}" == "NO" ]] || [[ "${input^^}" == "N" ]]; then
    info "Use default apt source"
  fi
else
  warn "Use default option: 'yes'"
  sed -i -E -r 's/deb\.debian\.org/mirrors\.tuna\.tsinghua\.edu\.cn/' "/etc/apt/sources.list"
fi

info "Updating..."
apt-get update -yqq \
  || warn "Failed to update, ignored."
apt-get upgrade -yqq -o Dpkg::Options::="--force-confdef" \
  || warn "Failed to upgrade, ignored"

info "Installing 'sudo'..."
apt-get install -yqq -o Dpkg::Options::="--force-confdef" sudo \
  || die_can_rerun "Failed to insatll package 'sudo'"

if ! [[ "$USER" == "root" ]]; then
  mkdir -p /etc/sudoers.d/
  {
    echo "# Generate by wine-desktop"
    echo "# This file allow user '$USER' use 'sudo' command"
    echo "$USER   ALL=(ALL:ALL) ALL"
  } > /etc/sudoers.d/wine-desktop
  info "Granted user '$USER' sudo privilege"
fi

info "Installing others packages..."
warn "Depending on your network, it may take a long time."
apt-get install -yqq -o Dpkg::Options::="--force-confdef" \
  git wget dpkg-dev cmake dh-cmake &> /dev/null \
  || warn "Failed to install some required packages, but can ignore it."

rm "/etc/profile.d/packages-installation.sh"

cat > "/etc/profile.d/installer-installation.sh" <<-__EOF__
#!/usr/bin/bash

if [[ -n "\$WINE_DESKTOP_CONTAINER" ]]; then
  echo "First install"
  cd "\$WINE_DESKTOP_CONTAINER"
  chmod +x "\$WINE_DESKTOP_CONTAINER/updater"
  bash "\$WINE_DESKTOP_CONTAINER/updater"
  sudo rm "/etc/profile.d/installer-installation.sh"
  echo "OK, please relogin"
  exit 0
fi
__EOF__

info "Everything is OK. =v="
info "Use 'start-debian' to login"
exit 0
