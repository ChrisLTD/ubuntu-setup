# modified from
# https://robots.thoughtbot.com/remote-development-machine
# https://raw.githubusercontent.com/kenyonj/init/master/init.sh
# and https://github.com/thoughtbot/laptop/tree/39768b19959f74724ed0c0ea92e5b2f6f78e45c1

fancy_echo() {
  printf "\n%b\n" "$1"
}

install_if_needed() {
  local package="$1"

  if [ $(dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    sudo aptitude install -y "$package";
  fi
}

append_to_bashrc() {
  local text="$1" bashrc
  local skip_new_line="$2"

  if [[ -w "$HOME/.bashrc" ]]; then
    bashrc="$HOME/.bashrc"
  else
    bashrc="$HOME/.bashrc"
  fi

  if ! grep -Fqs "$text" "$bashrc"; then
    if (( skip_new_line )); then
      printf "%s\n" "$text" >> "$bashrc"
    else
      printf "\n%s\n" "$text" >> "$bashrc"
    fi
  fi
}

#!/usr/bin/env bash

# Get user email
fancy_echo "What's your email address?"
  read emailvar

fancy_echo "What's your name?"
  read namevar

# trap EXIT to print failed message
trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT
set -e

if [[ ! -d "$HOME/.bin/" ]]; then
  mkdir "$HOME/.bin"
fi

if [ ! -f "$HOME/.bashrc" ]; then
  touch "$HOME/.bashrc"
fi

if ! grep -qiE 'wheezy|jessie|precise|trusty' /etc/os-release; then
  fancy_echo "Sorry! we don't currently support that distro."
  exit 1
fi

append_to_bashrc 'export PATH="$HOME/.bin:$PATH"'

fancy_echo "Updating system packages ..."
  if command -v aptitude >/dev/null; then
    fancy_echo "Using aptitude ..."
  else
    fancy_echo "Installing aptitude ..."
    sudo apt-get install -y aptitude
  fi

  sudo aptitude update

fancy_echo "Installing git, for source control management ..."
  install_if_needed git

fancy_echo "Installing base ruby build dependencies ..."
  sudo aptitude build-dep -y ruby1.9.3

fancy_echo "Installing libraries for common gem dependencies ..."
  sudo aptitude install -y libxslt1-dev libcurl4-openssl-dev libksba8 libksba-dev libqtwebkit-dev libreadline-dev

fancy_echo "Installing sqlite3, for prototyping database-backed rails apps"
  install_if_needed libsqlite3-dev
  install_if_needed sqlite3

fancy_echo "Installing Postgres, a good open source relational database ..."
  install_if_needed postgresql
  install_if_needed postgresql-server-dev-all

fancy_echo "Installing Redis, a good key-value database ..."
  install_if_needed redis-server

fancy_echo "Installing ctags, to index files for vim tab completion of methods, classes, variables ..."
  install_if_needed exuberant-ctags

fancy_echo "Installing vim ..."
  install_if_needed vim-gtk

fancy_echo "Installing ImageMagick, to crop and resize images ..."
  install_if_needed imagemagick

fancy_echo "Installing watch, to execute a program periodically and show the output ..."
  install_if_needed watch

fancy_echo "Installing curl ..."
  install_if_needed curl

fancy_echo "Installing node, to render the rails asset pipeline ..."
  install_if_needed nodejs

chruby_from_source() {
  wget -O /tmp/chruby-0.3.9.tar.gz https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz
  cd /tmp/
  tar -xzvf chruby-0.3.9.tar.gz
  cd /tmp/chruby-0.3.9/
  sudo make install
  cd
  rm -rf /tmp/chruby-0.3.9/

  append_to_bashrc 'source /usr/local/share/chruby/chruby.sh'
  append_to_bashrc 'source /usr/local/share/chruby/auto.sh'
}

ruby_install_from_source() {
  wget -O /tmp/ruby-install-0.5.0.tar.gz https://github.com/postmodern/ruby-install/archive/v0.5.0.tar.gz
  cd /tmp/
  tar -xzvf ruby-install-0.5.0.tar.gz
  cd /tmp/ruby-install-0.5.0/
  sudo make install
  cd
  rm -rf /tmp/ruby-install-0.5.0/
}

chruby_from_source
ruby_version="$(curl -sSL http://ruby.thoughtbot.com/latest)"

fancy_echo "Installing ruby-install for super easy installation of rubies..."
  ruby_install_from_source

fancy_echo "Installing Ruby $ruby_version ..."
  ruby-install ruby "$ruby_version"

fancy_echo "Loading chruby and changing to Ruby $ruby_version ..."
  source ~/.bashrc
  chruby $ruby_version

fancy_echo "Setting default Ruby to $ruby_version ..."
  append_to_bashrc "chruby ruby-$ruby_version"

fancy_echo "Updating to latest Rubygems version ..."
  gem update --system

fancy_echo "Installing Bundler to install project-specific Ruby gems ..."
  gem install bundler --no-document --pre

fancy_echo "Configuring Bundler for faster, parallel gem installation ..."
  number_of_cores=$(nproc)
  bundle config --global jobs $((number_of_cores - 1))

fancy_echo "Installing Heroku CLI client ..."
  curl -s https://toolbelt.heroku.com/install-ubuntu.sh | sh

fancy_echo "Installing the heroku-config plugin to pull config variables locally to be used as ENV variables ..."
  heroku plugins:install git://github.com/ddollar/heroku-config.git

# LAMP From digital ocean tutorial
# https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-14-04

fancy_echo "Installing Apache ..."
  install_if_needed apache2

fancy_echo "Installing MySQL ..."
  install_if_needed mysql-server
  install_if_needed php5-mysql

fancy_echo "Setting up MySQL ..."
  mysql_secure_installation

fancy_echo "Setting up PHP packages for Wordpress ..."
  install_if_needed php5-fpm
  install_if_needed php5-mysqlnd
  install_if_needed php5-gd
  install_if_needed php5-curl
  install_if_needed php5-gd libssh2-php

fancy_echo "Restarting Apache ..."
  service apache2 restart

fancy echo "Installing vim settings ..."
  git clone https://github.com/ChrisLTD/macvim_config.git ~/.vim

fancy echo "Pulling dotfiles ..."
  git clone https://github.com/ChrisLTD/ubuntu-setup.git ~/dotfiles

fancy echo "Symlinking gitconfig ..."
  ln -s ~/dotfiles/.gitconfig ~/.gitconfig

fancy echo "Setting git name and email address ..."
  git config user.email "$emailvar"
  git config user.name "$namevar"

fancy echo "Generating SSH key ..."
  ssh-keygen -t rsa -b 4096 -C "$emailvar"

fancy echo "Start SSH agent ..."
  eval "$(ssh-agent -s)"

fancy echo "Add new key to SSH agent ..."
  ssh-add ~/.ssh/id_rsa

Fancy echo "Copy your public key for adding to Github, etc. ..."
  cat ~/.ssh/id_rsa.pub

fancy_echo "Your public IP is ..."
  ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'