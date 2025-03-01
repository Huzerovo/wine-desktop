#!/usr/bin/bash

source common.sh

check_env() {
  if [[ "$(uname -o)" != "Android" ]]; then
    die "Please only run this script in Termux"
  fi

  # check prefix
  if [[ -z "$PREFIX" ]]; then
    export PREFIX="/data/data/com.termux/files/usr"
    if ! [[ -d "$PREFIX" ]]; then
      die "Can not find Termux prefix: '$PREFIX'"
    fi
    warn "env PREFIX is not set, set to '$PREFIX'"
  fi

  # check home
  if [[ -z "$HOME" ]]; then
    export HOME="/data/data/com.termux/files/home"
    if ! [[ -d "$HOME" ]]; then
      die "Can not find Termux home: '$HOME'"
    fi
    warn "env HOME is not set, set to '$HOME'"
  fi
}

require_termux_packages() {
  info "Updating..."
  pkg update || warn "Update failed, ignore it."

  info "Upgrading..."
  pkg upgrade -y || warn "Upgrade failed, ignore it."

  # install termux-x11
  if ! which termux-x11 &> /dev/null; then
    info "Installing termux-x11 tools"
    pkg install -y x11-repo \
      || die_can_retry "Failed to install package 'x11-repo'"
    pkg install -y termux-x11-nightly \
      || die_can_retry "Failed to install package 'termux-x11'"
  fi

  # install proot and install proot os
  if ! which proot-distro &> /dev/null; then
    info "Installing package 'proot-distro'..."
    pkg install -y proot-distro \
      || die_can_retry "Failed to install package 'proot-distro'"
  fi

  if ! which git &> /dev/null; then
    info "Installing git"
    pkg install -y git \
      || die_can_retry "Failed to install package 'git'"
  fi
  clear
}

install_os() {
  # check rootfs
  if ! [[ -d "$ROOTFS" ]]; then
    info "Installing ${CONFIG_OS} with proot-distro..."
    proot-distro install "$CONFIG_OS" \
      || die_can_retry "Failed to install ${CONFIG_OS}"
  fi
}

get_wine_desktop_installer() {
  # update wine-desktop-installer
  if [[ -d "wine-desktop-installer" ]]; then
    info "Using exist wine-desktop-installer, try to update"
    (cd "wine-desktop-installer" && {
      # try to update or force rebase
      git pull &> /dev/null || git rebase &> /dev/null
    }) || warn "Failed to update wine-desktop-installer, but ignore it"
  else
    info "Getting wine-desktop-installer"
    git clone "https://github.com/Huzerovo/wine-desktop-installer" &> /dev/null \
      || die_can_retry "Failed to clone wine-desktop-installer"
  fi
}

cache_wine_desktop() {
  # copy wine-desktop-installer to proot
  info "Install wine-desktop-installer to proot"
  if [[ -d "$ROOTFS_CACHE/wine-desktop" ]]; then
    rm -rf "$ROOTFS_CACHE/wine-desktop"
  fi
  cp -r "./wine-desktop-installer" "$ROOTFS_CACHE/wine-desktop"
}

install_login_installation() {
  # install login-installation
  mkdir -p "$ROOTFS/etc/profile.d"
  cp "./login-installation.sh" "$ROOTFS/etc/profile.d/login-installation.sh"
}

install_start_bin() {
  # install start bin
  info "Installing start-wine-desktop"
  mkdir -p "$HOME/.local/bin"
  if [[ -f "$HOME/.local/bin/start-wine-desktop" ]]; then
    warn "Found exist 'start-wine-desktop', keep it."
  else
    cp "start-wine-desktop" "$HOME/.local/bin" \
      || die_can_retry "Can not install start bin"
  fi
  chmod +x "$HOME/.local/bin/start-wine-desktop"
  warn "You should add the $HOME/.local/bin to your PATH, if you are using:"
  warn " - bash, add 'export \$PATH=\"\$PATH:\$HOME/.local/bin\"' to '$HOME/.bashrc'"
  warn " - fish, add 'export \$PATH=\"\$PATH:\$HOME/.local/bin\"' to '$HOME/.config/fish/conf.d/wine-desktop.fish'"
  warn " - zsh, add 'export \$PATH=\"\$PATH:\$HOME/.local/bin\"' to '$HOME/.zshrc'"
  export PATH="$PATH:$HOME/.local/bin"
}

try_login_installation() {
  local retry
  retry=0
  while ! { proot-distro login \
    --bind "$HOME":"/mnt/termux-home" \
    --env TERMUX_HOME="$HOME" \
    --shared-tmp --isolated "$CONFIG_OS"; }; do
    erro "Login install failed, will retry after 5 second, press 'q' to abort"
    read -t 5 -r line
    if [[ "$line" == "q" ]]; then
      exit 1
    fi
    ((retry++))
    if [[ $retry -gt 3 ]]; then
      erro "Max retry times, exit"
      exit 1
    fi
    info "retry $retry/3"
  done
  unset retry
}

main() {
  check_env

  export CONFIG_OS="ubuntu"
  export ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/${CONFIG_OS}"
  export ROOTFS_CACHE="$ROOTFS/var/cache"

  require_termux_packages
  install_os
  get_wine_desktop_installer
  cache_wine_desktop
  install_login_installation
  install_start_bin

  info "Termux installation Done."
  warn "Going to login installation"
  # login installation will modify start bin
  try_login_installation

  info "Ready to build and install wine-desktop-installer"
  start-wine-desktop

  unset ROOTFS
  unset ROOTFS_CACHE
}

main

# vim: ts=2 sts=2 sw=2
