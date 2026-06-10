#!/bin/bash
if [ "$EUID" -ne 0 ]; then echo "Usa sudo"; exit 1; fi

# --- VARIABLES ---
IP_KING="192.168.137.117"
IP_MANAGER="192.168.23.71"
IP_PROXY_DMZ="192.168.12.49"

# 1. Reset y Políticas base
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# 2. Gestión SSH
ufw allow from $IP_KING to any port 2235 proto tcp

# 3. Túnel WireGuard
ufw allow from $IP_MANAGER to any port 50281 proto udp

# 4. Tráfico interno Docker Swarm (Solo con el Manager)
ufw allow from $IP_MANAGER to any port 2377 proto tcp
ufw allow from $IP_MANAGER to any port 7946 proto tcp
ufw allow from $IP_MANAGER to any port 7946 proto udp
ufw allow from $IP_MANAGER to any port 4789 proto udp

# 5. Puertos de Aplicación
ufw allow from $IP_PROXY_DMZ to any port 6550 proto tcp
ufw allow from $IP_PROXY_DMZ to any port 6551 proto tcp

# 6. Habilitar
ufw --force enable

echo "======================================================================"
echo " OPERACIÓN COMPLETADA"
echo "======================================================================"