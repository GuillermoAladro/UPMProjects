#!/bin/sh
# Question 1 - Install containerd and Docker on the Debian VM. Run as root.
set -eu

# Refresh the package index before installing anything
apt update
apt upgrade

# Packages required to fetch and verify the Docker repository
apt install apt-transport-https ca-certificates curl gnupg

# Register Docker's signing key as trusted.
# The keyrings directory does not exist on a clean Debian install.
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the Docker APT repository for this Debian release
tee /etc/apt/sources.list.d/docker.sources <<SOURCES
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
SOURCES

apt update

# Engine, CLI, containerd runtime and the buildx / compose plugins
apt install docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# Membership in the docker group lets the student use the socket without sudo.
# The session must be reopened for the new group to take effect.
adduser estudiante docker
