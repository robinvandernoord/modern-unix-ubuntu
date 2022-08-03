#!/usr/bin/bash

# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
# Reset
Color_Off='\033[0m' # Text Reset

# Regular Colors
Black='\033[0;30m'  # Black
Red='\033[0;31m'    # Red
Green='\033[0;32m'  # Green
Yellow='\033[0;33m' # Yellow
Blue='\033[0;34m'   # Blue
Purple='\033[0;35m' # Purple
Cyan='\033[0;36m'   # Cyan
White='\033[0;37m'  # White

# Bold
BBlack='\033[1;30m'  # Black
BRed='\033[1;31m'    # Red
BGreen='\033[1;32m'  # Green
BYellow='\033[1;33m' # Yellow
BBlue='\033[1;34m'   # Blue
BPurple='\033[1;35m' # Purple
BCyan='\033[1;36m'   # Cyan
BWhite='\033[1;37m'  # White

# Underline
UBlack='\033[4;30m'  # Black
URed='\033[4;31m'    # Red
UGreen='\033[4;32m'  # Green
UYellow='\033[4;33m' # Yellow
UBlue='\033[4;34m'   # Blue
UPurple='\033[4;35m' # Purple
UCyan='\033[4;36m'   # Cyan
UWhite='\033[4;37m'  # White

# Background
On_Black='\033[40m'  # Black
On_Red='\033[41m'    # Red
On_Green='\033[42m'  # Green
On_Yellow='\033[43m' # Yellow
On_Blue='\033[44m'   # Blue
On_Purple='\033[45m' # Purple
On_Cyan='\033[46m'   # Cyan
On_White='\033[47m'  # White

# High Intensity
IBlack='\033[0;90m'  # Black
IRed='\033[0;91m'    # Red
IGreen='\033[0;92m'  # Green
IYellow='\033[0;93m' # Yellow
IBlue='\033[0;94m'   # Blue
IPurple='\033[0;95m' # Purple
ICyan='\033[0;96m'   # Cyan
IWhite='\033[0;97m'  # White

# Bold High Intensity
BIBlack='\033[1;90m'  # Black
BIRed='\033[1;91m'    # Red
BIGreen='\033[1;92m'  # Green
BIYellow='\033[1;93m' # Yellow
BIBlue='\033[1;94m'   # Blue
BIPurple='\033[1;95m' # Purple
BICyan='\033[1;96m'   # Cyan
BIWhite='\033[1;97m'  # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'  # Black
On_IRed='\033[0;101m'    # Red
On_IGreen='\033[0;102m'  # Green
On_IYellow='\033[0;103m' # Yellow
On_IBlue='\033[0;104m'   # Blue
On_IPurple='\033[0;105m' # Purple
On_ICyan='\033[0;106m'   # Cyan
On_IWhite='\033[0;107m'  # White

tempdir=$(mktemp -d)

function require_sudo {
  if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
  fi
}

function require_amd64 {
  bit=$(getconf LONG_BIT)
  if [[ $bit != 64 ]]; then
    echo "This script only works for 64bit Debian/Ubuntu-based machines."
    exit 1
  fi
}

function success {
  echo -e "$Green $1 $Color_Off"
}

function warn {
  echo -e "$Yellow $1 $Color_Off"
}

function fail {
  echo -e "$Red $1 $Color_Off"
}

function __install_dpkg {
  url=$1
  name=$2

  gum spin --spinner dot --title "wget $name" -- wget "$url" -O "$tempdir/$name.deb"
  gum spin --spinner dot --title "dpkg -i $name" -- dpkg -i "$tempdir/$name.deb"
}

function __install_apt {
  name=$1

  gum spin --spinner dot --title "apt install $name" -- apt install -y $name
}

function _install_gum {
  url="https://github.com/charmbracelet/gum/releases/download/v0.3.0/gum_0.3.0_linux_amd64.deb"

  # don't use __install_dpkg since gum isn't installed yet

  wget "$url" -O "$tempdir/gum.deb"
  apt install "$tempdir/gum.deb" -y
}

function install_gum {
  which gum >/dev/null && return || echo "installing gum" && _install_gum >/dev/null 2>/dev/null
  which gum >/dev/null && success "installed" || (fail "Failed installing gum" && exit 1)
}

function spin {
  name=$1
  alias method=$2

  gum spin --spinner dot --title "Installing $name..." $method
}

function _install_tool {
  name=$1
  description=$2
  method=$3

  gum confirm "Would you like to install $name? ($description)" && ($method && success "installed $name" || fail "error installing $name") || warn "skipped installing $name" # final || is for confirm = false
}

function install_bat {
  __install_apt bat
}

function setup_bat_alias {
  bashrc="/home/$SUDO_USER/.bashrc"

  which batcat > /dev/null 2> /dev/null || return

  grep 'alias bat' $bashrc >/dev/null && warn "alias bat already exists" || gum confirm "Would you like to setup the alias 'bat' for 'batcat'?" && echo -e "\nalias bat=batcat\n" >>$bashrc
}

function install_exa {
  __install_apt exa
}

function install_lsd {
  url="https://github.com/Peltoche/lsd/releases/download/0.22.0/lsd_0.22.0_amd64.deb"
  __install_dpkg $url "lsd"
}

function install_delta {
  url="https://github.com/dandavison/delta/releases/download/0.13.0/git-delta_0.13.0_amd64.deb"
  __install_dpkg $url "delta"
}

function show_delta_git_setup {
  echo "Write this to your git config if you want to use delta for git:"
  cat <<EOF
# ~/.gitconfig
[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only
[add.interactive]
    useBuiltin = false # required for git 2.37.0

[delta]
    navigate = true    # use n and N to move between diff sections
    light = false      # set to true if you're in a terminal w/ a light background color (e.g. the default macOS terminal)

[merge]
    conflictstyle = diff3

[diff]
    colorMoved = default
EOF
}

function install_dust {
  url="https://github.com/bootandy/dust/releases/download/v0.8.1/du-dust_0.8.1_amd64.deb"
  __install_dpkg $url "dust"
}

function install_duf {
  __install_apt "duf"
}

function install_broot {
  fail "broot is currently not supported"
}

function install_fd {
    __install_apt "fd-find"
}

function setup_fd_alias {
  which fd > /dev/null 2> /dev/null && warn "command fd already exists - not making alias" && return
  which fdfind > /dev/null 2> /dev/null && (ln -s $(which fdfind) /usr/bin/fd) || warn "fd not installed - not making alias"
}

function install_ripgrep {
  __install_apt ripgrep
}

function install_ag {
  __install_apt silversearcher-ag
}

function install {
  name=$1
  description=$2
  method=$3
  pkg=${4:-"$name"}

  which $pkg >/dev/null && warn "$name already installed" || _install_tool "$name" "$description" $method
}

function main {
  require_sudo
  require_amd64

  # gum can't use install since _install_tool uses gum
  install_gum

  install bat "Better cat" install_bat batcat
  setup_bat_alias

  install exa "A modern replacement for ls." install_exa

  install lsd "The next gen file listing command." install_lsd

  install delta "A syntax-highlighting pager for git, diff, and grep output" install_delta && show_delta_git_setup

  install dust "A more intuitive version of du written in rust." install_dust

  install duf "A better df alternative" install_duf

  install broot "A new way to see and navigate directory trees" install_broot

  install fd "A simple, fast and user-friendly alternative to find." install_fd fdfind
  setup_fd_alias

  install rg "[ripgrep] An extremely fast alternative to grep that respects your gitignore" install_ripgrep

  install ag "A code searching tool similar to ack, but faster." install_ag

  # ...
  # keep gum?
}

main

# todo: remove flag
# todo: menu with 1. install all; 2. install some; 3. remove all; 4. remove some
# sudo apt remove -y gum git-delta lsd exa bat du-dust duf fd-find ripgrep silversearcher-ag ...
