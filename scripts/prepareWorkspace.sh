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

# P4 Official Repo
bash -c "cat > /etc/apt/sources.list.d/home:p4lang.list <<EOF
deb http://download.opensuse.org/repositories/home:/p4lang/xUbuntu_22.04/ /
EOF"
curl 'http://download.opensuse.org/repositories/home:/p4lang/xUbuntu_22.04/Release.key' > /etc/apt/trusted.gpg.d/home:p4lang.asc

apt update
apt install -y --no-install-recommends \
    ant                     \
    curl                    \
    firefox                 \
    git                     \
    make                    \
    maven                   \
    mininet                 \
    openjdk-8-jdk-headless  \
    openvswitch-switch      \
    p4lang-p4c              \
    p4lang-bmv2             \
    p4lang-pi               \
    python-is-python3       \
    python3                 \
    python3-dev             \
    python3-tk		        \
    wireshark               \
    xbitmaps                \
    xdg-user-dirs           \
    xfce4                   \
    xfce4-session           \
    xfce4-terminal          \
    xrdp		            \
    xorgxrdp	 	        \
    xubuntu-icon-theme      \
    xterm
# Remove default JRE pre-installed by Ubuntu. Floodlight needs outdated JRE (1.8)
bash -c "dpkg-query --list 'openjdk-[^8]*' | grep ^ii | cut -d ' ' -f 3 | xargs apt -y remove"
apt autoremove -y

# Enable rootless wireshark
bash -c "yes | DEBIAN_FRONTEND=teletype dpkg-reconfigure wireshark-common"
usermod -aG wireshark ${USER_NAME}

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

# Desktop directory is named after user language settings
DESKTOP_DIR=$(su --login ${USER_NAME} --command "xdg-user-dir DESKTOP")

# Add Miniedit desktop icon
bash -c "cat > ${DESKTOP_DIR}/Miniedit.desktop <<EOF
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
bash -c "cat > ${DESKTOP_DIR}/Floodlight.desktop <<EOF
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
chmod +x ${DESKTOP_DIR}/*.desktop

chown $USER_UID:$USER_UID -R ${USER_DIR}

# Bypass enterprise "security" configurations to reach RDP Port
# Mask it as a FTP service.
# Given that 21 is a priviledged port and XRDP is run as an 
# unpriviledged user, we need to add a systemd capability in order 
# for the service to use such ports.
mkdir -p /etc/systemd/system/xrdp.service.d/
bash -c "cat > /etc/systemd/system/xrdp.service.d/override.conf <<EOF
[Service]
AmbientCapabilities=CAP_NET_BIND_SERVICE
EOF"
bash -c "sed -i s/port=3389/port=21/ /etc/xrdp/xrdp.ini"
systemctl daemon-reload
systemctl restart xrdp

ufw allow ssh
ufw allow 21/tcp
ufw --force enable
ufw reload
