#!/bin/bash

# Comprobacion de privilegios root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Por favor, ejecuta este script usando sudo."
  exit 1
fi

# Variables
PUB_KEY_KING="PEGAR_AQUI_LA_CLAVE_PUBLICA_DE_KING"
USR=$(logname)
IP_KING="192.168.137.117"

# 1. Configuracion de Netplan
cat << EOF > /etc/netplan/00-installer-config.yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    enp0s3:
      dhcp4: false
      accept-ra: false
  vlans:
    vlan235:
      id: 235
      link: enp0s3
      addresses:
        - 192.168.23.71/24
      routes:
        - to: default
          via: 192.168.23.1
      nameservers:
        addresses:
          - 192.168.23.1
  version: 2
EOF

netplan apply

# 2. Seguridad SSH y Llaves
apt install ssh -y
mkdir -p /home/$USR/.ssh
echo "$PUB_KEY_KING" > /home/$USR/.ssh/authorized_keys
chown -R $USR:$USR /home/$USR/.ssh
chmod 700 /home/$USR/.ssh
chmod 600 /home/$USR/.ssh/authorized_keys

# Hardening de sshd_config
sed -i 's/#Port 22/Port 2235/' /etc/ssh/sshd_config
sed -i 's/Port 22/Port 2235/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
echo "AllowUsers $USR@$IP_KING" >> /etc/ssh/sshd_config

systemctl daemon-reload 
systemctl restart ssh.socket

# 3. Configuracion de Fail2Ban
apt update
apt install fail2ban -y
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf.back

cat << EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port    = 2235
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 3
bantime = 1h
EOF

systemctl enable fail2ban
systemctl restart fail2ban

# 4. Seguridad sysctl (98-AS-tfg.conf)
cat << EOF > /etc/sysctl.d/98-AS-tfg.conf
# REDUCCIÓN DE SUPERFICIE
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

# PROTECCIÓN ANTI-SPOOFING
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# PROTECCIÓN ANTI-DOS
net.ipv4.tcp_syncookies = 1

# PROTECCIÓN ANTI-MITM
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
EOF

sysctl --system

echo "======================================================================"
echo " OPERACIÓN COMPLETADA"
echo "======================================================================"