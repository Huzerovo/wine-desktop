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
  warn "you can rerun this script to continue installation after problem solved"
  exit 1
}

info "Updating..."
pkg update &> /dev/null \
  || warn "Update failed, ignore it."

info "Upgrading..."
pkg upgrade -y -o Dpkg::Options::="--force-confdef" &> /dev/null \
  || warn "Upgrade failed, ignore it."

# install termux-x11
if ! which termux-x11 &> /dev/null; then
  info "Installing termux-x11 tools"
  pkg install -y x11-repo &> /dev/null \
    || die_can_rerun "Failed to install x11-repo"
  pkg install -y termux-x11-nightly &> /dev/null \
    || die_can_rerun "Failed to install termux-x11"
fi

if ! which git &> /dev/null; then
  info "Installing git"
  pkg install -y git &> /dev/null \
    || die_can_rerun "Failed to install git"
fi

# install proot and install debian
if ! which proot-distro &> /dev/null; then
  info "Installing package 'proot-distro'..."
  pkg install -y proot-distro \
    || die_can_rerun "Failed to install package 'proot-distro'"
fi

# check prefix
if [[ -z "$PREFIX" ]]; then
  export PREFIX="/data/data/com.termux/files/usr"
  warn "env \$PREFIX is not set, set to '$PREFIX'"
fi

# check home
if [[ -z "$HOME" ]]; then
  export HOME="/data/data/com.termux/files/home"
  warn "env \$HOME is not set, set to '$HOME'"
fi

# check debian rootfs
ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/debian"
if ! [[ -d "$ROOTFS" ]]; then
  info "Installing debian with proot..."
  proot-distro install debian &> /dev/null \
    || die_can_rerun "Failed to install debian"
fi

# install start bin
info "Installing start-debian"
mkdir -p "$HOME/.local/bin"
if [[ -f "$HOME/.local/bin/start-debian" ]]; then
  warn "Found exist 'start-debian', keep it."
else
  cp "start-debian" "$HOME/.local/bin/start-debian"
fi
chmod +x "$HOME/.local/bin/start-debian"
warn "You should add the $HOME/.local/bin to your PATH, if you are using:"
warn " - bash, add 'export \$PATH=\"\$PATH:\$HOME/.local/bin\"' to '$HOME/.bashrc'"
warn " - fish, add 'export \$PATH=\"\$PATH:\$HOME/.local/bin\"' to '$HOME/.config/fish/conf.d/wine-desktop.fish'"
warn " - zsh, add 'export \$PATH=\"\$PATH:\$HOME/.local/bin\"' to '$HOME/.zshrc'"
export PATH="$PATH:$HOME/.local/bin"

if [[ -d "wine-desktop-installer" ]]; then
  info "Using exist wine-desktop-installer, try to update"
  (cd "wine-desktop-installer" && {
    # try to update or force rebase
    git pull &> /dev/null || git rebase &> /dev/null ;
  }) || warn "Failed to update wine-desktop-installer, but ignore it"
else
  info "Getting wine-desktop-installer"
  git clone "https://github.com/Huzerovo/wine-desktop-installer" &> /dev/null \
    || die_can_rerun "Failed to clone wine-desktop-installer"
fi

# NOTE: all installation stored in /var/cache (next installation in /etc/profile.d)
# NOTE: all files stored in /var/cache/wine-desktop
# install wine-desktop-installer
ROOTFS_CACHE="$ROOTFS/var/cache"
info "Install wine-desktop-installer to proot"
# main wine installer
if [[ -d "$ROOTFS_CACHE/wine-desktop" ]]; then
  rm -r "$ROOTFS_CACHE/wine-desktop"
fi
cp -r "./wine-desktop-installer" "$ROOTFS_CACHE/wine-desktop"

# install login-installation
mkdir -p "$ROOTFS/etc/profile.d"
cp "./login-installation.sh" "$ROOTFS/etc/profile.d/login-installation.sh"
# install installation script
cp "./packages-installation.sh" "$ROOTFS_CACHE"

unset ROOTFS
unset ROOTFS_CACHE

info "Termux installation Done."
warn "Going to login installation"

# do login-installation
RETRY=0
while ! { proot-distro login \
  --bind "$HOME":"/mnt/termux-home" \
  --env TERMUX_HOME="$HOME" \
  --shared-tmp --isolated debian; }; do
  erro "Login install failed, will retry after 3 second, press 'q' to abort"
  read -t 3 -r line
  if [[ "$line" == "q" ]]; then
    exit 1
  fi
  ((RETRY++))
  if [[ $RETRY -gt 3 ]]; then
    erro "Max retry times, exit"
    exit 1
  fi
  info "retry $RETRY/3"
done
unset RETRY

# do packages-installation
warn "Going to packages installation"
proot-distro login debian

warn "Ready to build and install wine-desktop-installer"
start-debian
