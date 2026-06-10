#!/bin/bash

# Comprobacion de privilegios root
if [ "$EUID" -ne 0 ]; then 
  echo "Error: Por favor, ejecuta este script usando sudo."
  exit 1
fi

# Variables
USR=$(logname)
HOME_USR="/home/$USR"
KEY_PASSPHRASE="CAMBIAME!"

# 1. Configuracion de Netplan (KING - VLAN 137)
# Usamos renderer NetworkManager para Linux Mint
cat << EOF > /etc/netplan/01-network-manager-all.yaml
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp0s3:
      accept-ra: false
      dhcp4: false
  vlans:
    vlan137:
      id: 137
      link: enp0s3
      addresses:
        - 192.168.137.117/24
      routes:
        - to: default
          via: 192.168.137.1
      nameservers:
        addresses:
          - 192.168.137.1
EOF

netplan apply

# 2. Generacion de llaves SSH
# Solo se genera si no existe ya una para no sobreescribirla
if [ ! -f "$HOME_USR/.ssh/id_rsa" ]; then
    sudo -u "$USR" ssh-keygen -t rsa -b 4096 -f "$HOME_USR/.ssh/id_rsa" -C "KING" -N "$KEY_PASSPHRASE"
    echo "Llave SSH generada correctamente."
else
    echo "Ya existe una llave SSH, saltando generacion."
fi

# 3. Seguridad sysctl (98-AS-tfg.conf)
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

# 4. añadimos en la lista de hosts las paginas del tfg
cat << EOF >> /etc/hosts
# Entradas para el TFG
192.168.23.71  portainer.local
192.168.23.71  moodle.tfg.local
192.168.23.71  web.tfg.local
EOF

# Finalizacion y muestra de la llave
echo ""
echo "======================================================================"
echo " OPERACIÓN COMPLETADA"
echo "======================================================================"
echo "Copia esta llave publica para pegarla en tus otros scripts:"
echo ""
cat "$HOME_USR/.ssh/id_rsa.pub"
echo ""
echo "======================================================================"