#!/bin/bash

# --- VARIABLE DE RED ---
IP_KING="192.168.137.117"

if [ "$EUID" -ne 0 ]; then 
  echo "Por favor, usa sudo."
  exit 1
fi

# 1. Reset y Políticas base
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# 2. SSH Administrativo (Solo KING al puerto 2313)
ufw allow from $IP_KING to any port 2313 proto tcp comment 'SSH desde KING'

# 3. Tráfico SQL entrante (Puerto 7704)
# Solo permitimos que el KING y los nodos web conecten al Proxy
ufw allow from $IP_KING to any port 7704 proto tcp comment 'Admin SQL desde KING'
ufw allow from 192.168.23.71 to any port 7704 proto tcp comment 'Tráfico SQL desde manager'
ufw allow from 192.168.23.21 to any port 7704 proto tcp comment 'Tráfico SQL desde worker'

# 4. Habilitar
ufw --force enable

echo "======================================================================"
echo " OPERACIÓN COMPLETADA"
echo "======================================================================"