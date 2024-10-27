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
while read -r -p "(default $PROOT_USER): " username; do
  if [[ -z "$username" ]]; then
    info "Use default user $PROOT_USER."
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
    warn "Use other user: '$PROOT_USER'"
  fi
  break
done

if user_exist "$PROOT_USER"; then
  info "Use exist user: $PROOT_USER"
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
  warn "The default password is: $PROOT_USER"
fi

# install wine desktop installer for user
# NOTE: all files are in /var/cache/wine-desktop, so just move the folder
WINE_DESKTOP_CONTAINER="$PROOT_HOME/.local/share/wine-desktop"

if [[ -d "$PROOT_HOME" ]]; then
  # remove old installation
  if [[ -d "$WINE_DESKTOP_CONTAINER" ]]; then
    rm -rf "$WINE_DESKTOP_CONTAINER"
  fi
  mv "/var/cache/wine-desktop" "$WINE_DESKTOP_CONTAINER"
  chown "$PROOT_USER":"$PROOT_USER" -R "$PROOT_HOME"
else
  warn "User is created but can not find the home."
  warn "Please move /var/cache/wine-desktop to $WINE_DESKTOP_CONTAINER manually."
fi

# config the start-debian
START_BIN="/mnt/termux-home/.local/bin/start-debian"
if [[ -w "$START_BIN" ]]; then
  sed -i -E -r "/^PROOT_USER=.*$/c\PROOT_USER=\"$PROOT_USER\"" "$START_BIN"
  sed -i -E -r "/^PROOT_HOME=.*$/c\PROOT_HOME=\"$PROOT_HOME\"" "$START_BIN"
  sed -i -E -r "/^WINE_DESKTOP_CONTAINER=.*$/c\WINE_DESKTOP_CONTAINER=\"\$PROOT_HOME/.local/share/wine-desktop\"" "$START_BIN"
fi

# remove self
rm -f /etc/profile.d/login-installation.sh

# generate essential packages-installation script
{
  echo "#!/usr/bin/bash"
  echo "USER=\"$PROOT_USER\""
  cat "/var/cache/packages-installation.sh"
} > "/etc/profile.d/packages-installation.sh"
rm "/var/cache/packages-installation.sh"

warn "Please relogin by 'proot-distro login debian' to install required packages."

exit 0
