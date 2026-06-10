#!/bin/bash

# --- VARIABLES DE RED ---
IP_KING="192.168.137.117"
IP_PROXYSQL="192.168.45.49"

# IPs de los nodos del clúster
G1="192.168.45.51"
G2="192.168.45.52"
G3="192.168.45.53"

if [ "$EUID" -ne 0 ]; then 
  echo "Por favor, usa sudo."
  exit 1
fi

# Detectar IP local para saber qué puerto 440X abrir
IP_LOCAL=$(hostname -I | awk '{print $1}')

case $IP_LOCAL in
  $G1) MY_SQL_PORT="4401"; PARTNERS=("$G2" "$G3") ;;
  $G2) MY_SQL_PORT="4402"; PARTNERS=("$G1" "$G3") ;;
  $G3) MY_SQL_PORT="4403"; PARTNERS=("$G1" "$G2") ;;
  *) echo "IP no reconocida como nodo Galera"; exit 1 ;;
esac

echo "Configurando Firewall para $IP_LOCAL (Puerto SQL: $MY_SQL_PORT)..."

# 1. Reset y Políticas base
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# 2. SSH Administrativo (Solo desde el KING al puerto 2313)
ufw allow from $IP_KING to any port 2313 proto tcp comment 'SSH desde KING'

# 3. Acceso SQL (Solo desde ProxySQL y KING)
ufw allow from $IP_PROXYSQL to any port $MY_SQL_PORT proto tcp comment 'SQL desde ProxySQL'
ufw allow from $IP_KING to any port $MY_SQL_PORT proto tcp comment 'SQL Admin desde KING'

# 4. Replicación Galera (SOLO entre nodos del clúster)
for partner in "${PARTNERS[@]}"; do
    # 4567: Galera Cluster (TCP/UDP)
    ufw allow from $partner to any port 4567 proto tcp
    ufw allow from $partner to any port 4567 proto udp
    # 4568: IST (Incremental State Transfer)
    ufw allow from $partner to any port 4568 proto tcp
    # 4444: SST (State Snapshot Transfer)
    ufw allow from $partner to any port 4444 proto tcp
done

# 5. Habilitar
ufw --force enable

echo "======================================================================"
echo " OPERACIÓN COMPLETADA: Puertos de replicación abiertos SOLO para: ${PARTNERS[*]}"
echo "======================================================================"