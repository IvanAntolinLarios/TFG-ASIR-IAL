#!/bin/bash
if [ "$EUID" -ne 0 ]; then echo "Usa sudo"; exit 1; fi

# --- VARIABLES ---
IP_KING="192.168.137.117"
IP_WORKER="192.168.23.21"
IP_PROXY_DMZ="192.168.12.49" # Tu ProxyHTTPS

# 1. Reset y Políticas base
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# 2. Gestión SSH
ufw allow from $IP_KING to any port 2235 proto tcp comment 'SSH desde KING'

# 3. Túnel WireGuard
ufw allow from $IP_WORKER to any port 50281 proto udp comment 'VPN con Worker'

# 4. Tráfico interno Docker Swarm (Solo con el Worker)
# Gestión del clúster
ufw allow from $IP_WORKER to any port 2377 proto tcp
# Comunicación entre nodos (Gossip)
ufw allow from $IP_WORKER to any port 7946 proto tcp
ufw allow from $IP_WORKER to any port 7946 proto udp
# Red Overlay (Tráfico de contenedores)
ufw allow from $IP_WORKER to any port 4789 proto udp

# 5. Puertos de Aplicación (Entrada desde el Proxy DMZ)
ufw allow from $IP_PROXY_DMZ to any port 6550 proto tcp comment 'Web TFG'
ufw allow from $IP_PROXY_DMZ to any port 6551 proto tcp comment 'Moodle'
# 6. Puertos de Aplicación (Entrada desde el Admin)
ufw allow from $IP_KING to any port 6550 proto tcp comment 'Web TFG'
ufw allow from $IP_KING to any port 6551 proto tcp comment 'Moodle'
ufw allow from $IP_KING to any port 9451 proto tcp comment 'Portainer'

# 7. Servicios sobre la interfaz VPN (wg0) - Alta Seguridad
# Solo permitimos NFS y Registry si vienen por dentro del túnel (10.99.0.x)
ufw allow in on wg0 from 10.99.0.2 to any port 2049 proto tcp comment 'NFS por VPN'
ufw allow in on wg0 from 10.99.0.2 to any port 5000 proto tcp comment 'Registry por VPN'

# 8. Habilitar
ufw --force enable

echo "======================================================================"
echo " OPERACIÓN COMPLETADA"
echo "======================================================================"