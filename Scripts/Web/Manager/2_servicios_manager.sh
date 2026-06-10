#!/bin/bash

# Comprobacion de privilegios
if [ "$EUID" -ne 0 ]; then 
  echo "Error: Por favor, ejecuta este script usando sudo."
  exit 1
fi

USR=$(logname)
IP_MANAGER="192.168.23.71"

# 1. Instalación de Docker
apt update && apt upgrade -y
apt install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
usermod -aG docker $USR

# 2. Inicialización de Docker Swarm
docker swarm init --advertise-addr $IP_MANAGER

# 3. Preparación de WireGuard (Instalación y llaves)
apt install wireguard -y
cd /etc/wireguard
umask 077
wg genkey > privatekey
wg pubkey < privatekey > publickey

# 4. Configuración de Almacenamiento Compartido (NFS)
apt install -y nfs-kernel-server
mkdir -p /var/nfs_tfg/web
mkdir -p /var/nfs_tfg/moodle_data

# Mover archivos de la web si ya existen en el home
if [ -d "/home/$USR/CARPETA-WEB" ]; then
    cp -r /home/$USR/CARPETA-WEB/* /var/nfs_tfg/web/
fi

chown -R nobody:nogroup /var/nfs_tfg
chmod -R 777 /var/nfs_tfg

# Configuración de exportaciones (Vía túnel VPN 10.99.0.x)
echo "/var/nfs_tfg 10.99.0.1(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
echo "/var/nfs_tfg 10.99.0.2(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
exportfs -a
systemctl restart nfs-kernel-server

echo "======================================================================"
echo " OPERACIÓN COMPLETADA"
echo "======================================================================"
echo " CLAVE PÚBLICA WIREGUARD (MANAGER):"
cat /etc/wireguard/publickey
echo ""
echo " COMANDO PARA UNIR WORKER:"
docker swarm join-token worker | grep "docker swarm join"
echo "======================================================================"