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
    openjdk-8-jdk-headless  \
    python-is-python3       \
    python3                 \
    python3-dev             \
    python3-tk		        \
    xfce4                   \
    xfce4-session           \
    xrdp		            \
    xorgxrdp	 	        \
    xubuntu-icon-theme
# Remove default JRE pre-installed by Ubuntu. Floodlight needs outdated JRE (1.8)
bash -c "dpkg-query --list 'openjdk-[^8]*' | grep ^ii | cut -d ' ' -f 3 | xargs apt -y remove"
apt autoremove -y

echo xfce4-session > ${USER_DIR}/.xsession
systemctl enable --now xrdp
# TIP: to change keyboard layout after this unattended install run
#   dpkg-reconfigure keyboard-configuration

# Enable root application to use Xorg server
bash -c "echo 'xhost +' >> ${USER_DIR}/.bashrc"

# Install floodlight and miniedit
su --login ${USER_NAME} \
   --command "
    curl --location --silent --remote-name https://raw.githubusercontent.com/mininet/mininet/master/examples/miniedit.py
    chmod +x ${USER_DIR}/miniedit.py
    curl --location --silent --remote-name https://github.com/floodlight/floodlight/archive/refs/tags/v1.2.tar.gz
    tar xf v1.2.tar.gz
    cd ${USER_DIR}/floodlight-1.2
    ant
"

# Create well-known user directories
su --login ${USER_NAME} \
   --command "xdg-user-dirs-update"

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
Path=${USER_DIR}/floodlight-1.2
Terminal=true
StartupNotify=false
EOF"

# Make desktop icons executable, otherwise XFCE4 will popup consent
chmod +x ${USER_DIR}/Desktop/*.desktop

chown $USER_UID:$USER_UID -R ${USER_DIR}

# Bypass enterprise "security" configurations to reach RDP Port
# Mask it as a DNS service
mv /etc/ufw/before.rules /etc/ufw/before.rules.bak
bash -c "cat > /etc/ufw/before.rules <<EOF
*nat
:PREROUTING ACCEPT [0:0]
-A PREROUTING -p tcp --dport 53 -j REDIRECT --to-port 3389
COMMIT
EOF"
bash -c "cat /etc/ufw/before.rules.bak >> /etc/ufw/before.rules"

ufw allow ssh
ufw allow 53
ufw --force enable
ufw reload
ufw disable
