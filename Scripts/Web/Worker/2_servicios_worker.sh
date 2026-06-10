#!/bin/bash

if [ "$EUID" -ne 0 ]; then 
  echo "Error: Por favor, ejecuta este script usando sudo."
  exit 1
fi
# --- VARIABLES ---
PUBKEY_MANAGER="PEGA_AQUI_LA_CLAVE_PÚBLICA__DE_WIREGUARD_DEL_MANAGER"
USR=$(logname)

# 1. Instalación de Docker
apt update && apt install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker $USR

# 2. WireGuard y Cliente NFS
apt install -y wireguard nfs-common
cd /etc/wireguard
umask 077
wg genkey > privatekey
wg pubkey < privatekey > publickey
PRIVKEY_WORKER=$(cat privatekey)

cat << EOF > /etc/wireguard/wg0.conf
[Interface]
# La IP que tendrá este Worker dentro del túnel
Address = 10.99.0.2/24

PrivateKey = $PRIVKEY_WORKER
MTU = 1280

[Peer]
# La IP real del Manager y el puerto UDP (Endpoint)
PublicKey = $PUBKEY_MANAGER
Endpoint = 192.168.23.71:50281
AllowedIPs = 10.99.0.1/32
PersistentKeepalive = 25
EOF

systemctl enable --now wg-quick@wg0

# 2. Configurar Insecure Registry
cat << 'EOF' > /etc/docker/daemon.json
{
  "insecure-registries" : ["10.99.0.1:5000"],
  "registry-mirrors": ["https://mirror.gcr.io"]
}
EOF
systemctl restart docker

echo "======================================================================"
echo " OPERACIÓN COMPLETADA"
echo "======================================================================"
echo " CLAVE PÚBLICA WIREGUARD (WORKER):"
cat /etc/wireguard/publickey
echo ""
echo " Recuerda unirte al Swarm con el token del Manager"
echo "======================================================================"