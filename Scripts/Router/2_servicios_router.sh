#!/bin/bash

# Comprobacion de privilegios root
if [ "$EUID" -ne 0 ]; then 
  echo "Error: Por favor, ejecuta este script usando sudo."
  exit 1
fi

# ==========================================================
# 0. VARIABLES DE CONFIGURACIÓN (EDITAR ANTES DE EJECUTARLO)
# ==========================================================

# --- NODO ADMINISTRADOR (KING) ---
K_IP="192.168.137.117"
K_MAC="08:00:27:4D:D6:14"

# --- DMZ (ProxyHTTP / Traefik) ---
P_HTTP_IP="192.168.12.49"
P_HTTP_MAC="08:00:27:35:FE:D9"

# --- CLUSTER WEB (Docker Swarm) ---
D_MANAGER_IP="192.168.23.71"
D_MANAGER_MAC="08:00:27:DC:7B:B8"
D_WORKER1_IP="192.168.23.21"
D_WORKER1_MAC="08:00:27:1A:78:B3"

# --- CLUSTER DATA (ProxySQL / MariaDB) ---
PSQL_IP="192.168.45.49"
DB1_IP="192.168.45.51"
DB2_IP="192.168.45.52"
DB3_IP="192.168.45.53"

# ==========================================================
# 1. HABILITAR IP FORWARDING (MOTOR DEL ROUTER)
# ==========================================================

echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-forwarding.conf
sysctl -p /etc/sysctl.d/99-forwarding.conf

# ==========================================================
# 2. CONFIGURACIÓN DE DNSMASQ (RESOLUCIÓN DNS)
# ==========================================================

# Liberar puerto 53 de systemd-resolved
sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
systemctl restart systemd-resolved
rm /etc/resolv.conf
ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

# Instalacion
apt update && apt install dnsmasq -y

# Configuracion limpia
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup
cat << EOF > /etc/dnsmasq.conf
no-resolv
server=1.1.1.1
server=8.8.8.8
domain-needed
bogus-priv
listen-address=127.0.0.1
listen-address=192.168.137.1
listen-address=192.168.12.1
listen-address=192.168.23.1
listen-address=192.168.45.1
bind-interfaces
cache-size=1000
EOF

systemctl restart dnsmasq

# ==========================================================
# 3. FIREWALL IPTABLES (POLÍTICAS ZERO TRUST)
# ==========================================================

# Limpieza total
iptables -F
iptables -t nat -F
iptables -X

# Politicas base (Cerrar frontera)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Trafico interno y estado
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Servicio DNS para las VLANs
iptables -A INPUT -i vlan+ -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i vlan+ -p tcp --dport 53 -j ACCEPT

# Salida a Internet (NAT)
iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
iptables -A FORWARD -i vlan+ -o enp0s3 -j ACCEPT

# Entrada desde Internet (DNAT a DMZ)
iptables -t nat -A PREROUTING -i enp0s3 -p tcp --dport 443 -j DNAT --to-destination $P_HTTP_IP:443
iptables -A FORWARD -i enp0s3 -o vlan371 -d $P_HTTP_IP -p tcp --dport 443 -j ACCEPT

# Microsegmentacion: DMZ -> WEB
iptables -A FORWARD -i vlan371 -o vlan235 -s $P_HTTP_IP -m mac --mac-source $P_HTTP_MAC -p tcp --dport 6550 -j ACCEPT
iptables -A FORWARD -i vlan371 -o vlan235 -s $P_HTTP_IP -m mac --mac-source $P_HTTP_MAC -p tcp --dport 6551 -j ACCEPT

# Microsegmentacion: WEB -> DATA
iptables -A FORWARD -i vlan235 -o vlan313 -s $D_WORKER1_IP -m mac --mac-source $D_WORKER1_MAC -d $PSQL_IP -p tcp --dport 7704 -j ACCEPT
iptables -A FORWARD -i vlan235 -o vlan313 -s $D_MANAGER_IP -m mac --mac-source $D_MANAGER_MAC -d $PSQL_IP -p tcp --dport 7704 -j ACCEPT

# Acceso Administrador (KING)
iptables -A INPUT -i vlan137 -s $K_IP -m mac --mac-source $K_MAC -p tcp --dport 2137 -j ACCEPT
iptables -A FORWARD -i vlan137 -o vlan371 -s $K_IP -m mac --mac-source $K_MAC -p tcp --dport 2371 -j ACCEPT
iptables -A FORWARD -i vlan137 -o vlan235 -s $K_IP -m mac --mac-source $K_MAC -p tcp --dport 2235 -j ACCEPT
iptables -A FORWARD -i vlan137 -o vlan313 -s $K_IP -m mac --mac-source $K_MAC -p tcp --dport 2313 -j ACCEPT
iptables -A FORWARD -i vlan137 -o vlan235 -s $K_IP -m mac --mac-source $K_MAC -d $D_MANAGER_IP -p tcp --dport 9451 -j ACCEPT
iptables -A FORWARD -i vlan137 -o vlan235 -s $K_IP -m mac --mac-source $K_MAC -p tcp --dport 6550 -j ACCEPT
iptables -A FORWARD -i vlan137 -o vlan235 -s $K_IP -m mac --mac-source $K_MAC -p tcp --dport 6551 -j ACCEPT
iptables -A FORWARD -i vlan137 -o vlan313 -s $K_IP -m mac --mac-source $K_MAC -d $PSQL_IP -p tcp --dport 7704 -j ACCEPT
iptables -A FORWARD -i vlan137 -o vlan313 -s $K_IP -m mac --mac-source $K_MAC -d $DB1_IP -p tcp --dport 4401 -j ACCEPT
iptables -A FORWARD -i vlan137 -o vlan313 -s $K_IP -m mac --mac-source $K_MAC -d $DB2_IP -p tcp --dport 4402 -j ACCEPT
iptables -A FORWARD -i vlan137 -o vlan313 -s $K_IP -m mac --mac-source $K_MAC -d $DB3_IP -p tcp --dport 4403 -j ACCEPT
iptables -A FORWARD -i vlan137 -s $K_IP -m mac --mac-source $K_MAC -p icmp --icmp-type echo-request -j ACCEPT

# =======================================================
# 4. PERSISTENCIA DE REGLAS
# =======================================================
apt install iptables-persistent -y
netfilter-persistent save

echo "======================================================================"
echo " OPERACIÓN COMPLETADA"
echo "======================================================================"