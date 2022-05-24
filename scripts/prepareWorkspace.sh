#!/usr/bin/bash

set -x

USER_UID=1000
USER_DIR=$(getent passwd $USER_UID | cut -d ':' -f 6)
USER_NAME=$(getent passwd 1000 | cut -d ':' -f 1)
export DEBIAN_FRONTEND=noninteractive

# Use APT with official repos
bash -c "cat > /etc/apt/sources.list <<EOF
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted
deb http://archive.ubuntu.com/ubuntu/ jammy universe
deb http://archive.ubuntu.com/ubuntu/ jammy-updates universe
deb http://archive.ubuntu.com/ubuntu/ jammy multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted
deb http://security.ubuntu.com/ubuntu/ jammy-security universe
deb http://security.ubuntu.com/ubuntu/ jammy-security multiverse
EOF"

echo 'nameserver 1.1.1.1' >> /etc/resolv.conf

apt update
apt upgrade -y

# Use APT with official repos
bash -c "cat > /etc/apt/sources.list <<EOF
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted
deb http://archive.ubuntu.com/ubuntu/ jammy universe
deb http://archive.ubuntu.com/ubuntu/ jammy-updates universe
deb http://archive.ubuntu.com/ubuntu/ jammy multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted
deb http://security.ubuntu.com/ubuntu/ jammy-security universe
deb http://security.ubuntu.com/ubuntu/ jammy-security multiverse
EOF"

echo 'nameserver 1.1.1.1' >> /etc/resolv.conf

apt update
apt remove -y \
    snapd
apt install -y --no-install-recommends \
    ant                     \
    curl                    \
    git                     \
    maven                   \
    mininet                 \
    openjdk-17-jre-headless \
    python-is-python3       \
    python3                 \
    python3-dev             \
    xfce4                   \
    xfce4-session           \
    xrdp
apt autoremove -y

echo xfce4-session > ${USER_DIR}/.xsession
systemctl enable --now xrdp
# TIP: to change keyboard layout after this unattended install run
#   dpkg-reconfigure keyboard-configuration

# Install floodlight and miniedit
su --login ${USER_NAME} \
   --command <<EOF
    curl --location --silent --remote-name https://raw.githubusercontent.com/mininet/mininet/master/examples/miniedit.py
    git clone --recursive git://github.com/floodlight/floodlight.git ${USER_DIR}/floodlight
    pushd ${USER_DIR}/floodlight
    ant
    popd
EOF

# Add Miniedit desktop icon
bash -c "cat > ${USER_DIR}/Desktop/Miniedit.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Miniedit
Comment=
Exec=sudo ${USER_DIR}/miniedit.py
Icon=preferences-system-network
Path=${USER_DIR}
Terminal=true
StartupNotify=false
EOF"

# Add Floodlight desktop icon
bash -c "cat > ${USER_DIR}/Desktop/Floodlight.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Floodlight
Comment=
Exec=sudo java -jar target/floodlight.jar
Icon=gnome-network-properties
Path=${USER_DIR}/floodlight
Terminal=true
StartupNotify=false
EOF"

chown $USER_UID:$USER_UID -R ${USER_DIR}
