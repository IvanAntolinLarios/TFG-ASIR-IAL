#!/bin/bash
if [ "$EUID" -ne 0 ]; then echo "Usa sudo"; exit 1; fi

IP_KING="192.168.137.117"

# 1. Reset
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# 2. Permitir solo SSH desde el KING
ufw allow from $IP_KING to any port 2371 proto tcp comment 'Gestión KING'

# 3. Permitir solo HTTPS (Puerto 443)
ufw allow 443/tcp comment 'Solo Tráfico Cifrado'

# 4. Habilitar
ufw --force enable

echo "======================================================================"
echo " OPERACIÓN COMPLETADA"
echo "======================================================================"