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

user_exist() {
  grep -e "^$1:" /etc/passwd &> /dev/null
}

invalid_user() {
  if [[ "$1" == "$(echo "$1" | sed -n -E -r "/^[a-z][a-z0-9_-]{2,30}$/p")" ]]; then
    return 1
  fi
  return 0
}

info "Welcome to login-installation."

PROOT_USER="root"
PROOT_HOME="/root"

info "Who will you run wine desktop as?"
while read -r -p "(default '$PROOT_USER'): " username; do
  if [[ -z "$username" ]]; then
    info "Use default user '$PROOT_USER'."
    break
  fi

  if invalid_user "$username"; then
    erro "Invalid user name '$username', require:"
    erro " 1. only cantains:"
    erro "    - small letter (a-z)"
    erro "    - number (0-9)"
    erro "    - short dash (-)"
    erro "    - underline (_)"
    erro " 2. start with small letter"
    continue
  fi

  if ! [[ "$PROOT_USER" == "$username" ]]; then
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

# install wine desktop installer for user
# NOTE: all files are in /var/cache/wine-desktop, so just move the folder
WINE_DESKTOP_CONTAINER="$PROOT_HOME/.local/share/wine-desktop"

if [[ -d "$PROOT_HOME" ]]; then
  # update old installation
  cp -rf "/var/cache/wine-desktop" "$(dirname "$WINE_DESKTOP_CONTAINER")"
  chown "$PROOT_USER":"$PROOT_USER" -R "$PROOT_HOME"
  rm -rf "/var/cache/wine-desktop"
else
  warn "User is created but can not find the home."
  warn "Please move '/var/cache/wine-desktop' to '$WINE_DESKTOP_CONTAINER' manually."
fi

# config the start-debian
START_BIN="/mnt/termux-home/.local/bin/start-debian"
if [[ -w "$START_BIN" ]]; then
  sed -i -E -r "/^PROOT_USER=.*$/c\PROOT_USER=\"$PROOT_USER\"" "$START_BIN"
  sed -i -E -r "/^PROOT_HOME=.*$/c\PROOT_HOME=\"$PROOT_HOME\"" "$START_BIN"
  sed -i -E -r "/^WINE_DESKTOP_CONTAINER=.*$/c\WINE_DESKTOP_CONTAINER=\"\$PROOT_HOME/.local/share/wine-desktop\"" "$START_BIN"
fi

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
  info "Use default option: 'yes'"
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

if ! [[ "$PROOT_USER" == "root" ]]; then
  mkdir -p /etc/sudoers.d/
  {
    echo "# Generate by wine-desktop"
    echo "# This file allow user '$PROOT_USER' use 'sudo' command"
    echo "$PROOT_USER   ALL=(ALL:ALL) ALL"
  } > /etc/sudoers.d/wine-desktop
  info "Granted user '$PROOT_USER' sudo privilege"
fi

info "Installing others packages..."
warn "Depending on your network, it may take a long time."
apt-get install -yqq -o Dpkg::Options::="--force-confdef" \
  git wget dpkg-dev cmake dh-cmake &> /dev/null \
  || warn "Failed to install some required packages, but can ignore it."

# install wine-desktop-installer next login
cat > "/etc/profile.d/installer-installation.sh" <<-__EOF__
#!/usr/bin/bash

if [[ -n "\$WINE_DESKTOP_CONTAINER" ]]; then
  cd "\$WINE_DESKTOP_CONTAINER"
  bash "\$WINE_DESKTOP_CONTAINER/updater"
  sudo rm "/etc/profile.d/installer-installation.sh"
  echo "OK, please relogin"
  exit 0
fi
__EOF__

info "Everything is OK. =v="
info "Use 'start-debian' to login"

# remove self
rm -f /etc/profile.d/login-installation.sh

exit 0
