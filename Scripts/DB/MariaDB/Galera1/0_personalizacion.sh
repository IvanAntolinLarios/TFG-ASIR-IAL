#!/bin/bash

# Comprobacion de privilegios root
if [ "$EUID" -ne 0 ]; then 
  echo "Error: Por favor, ejecuta este script usando sudo."
  exit 1
fi

# 1. Personalizacion del prompt (PS1)
# Estilo simple con logname para el usuario real
cat << 'EOF' >> /home/$(logname)/.bashrc
# PS1 Personalizado - Usuario Base
export PS1='\[\e[97;46m\] GALERA \[\e[0m\]\[\e[30;43m\] 1 \[\e[0m\] \[\e[1;37m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
EOF

# Usuario ROOT
cat << 'EOF' >> /root/.bashrc
# PS1 Personalizado - ROOT
export PS1='\[\e[97;41m\] [ ROOT @ GALERA 1 ] \[\e[0m\] \[\e[1;33m\]\u\[\e[0m\]:\[\e[1;31m\]\w\[\e[0m\]# '
EOF

# 2. Desactivar mensajes por defecto de Ubuntu
chmod -x /etc/update-motd.d/00-header
chmod -x /etc/update-motd.d/10-help-text
chmod -x /etc/update-motd.d/50-landscape-sysinfo
chmod -x /etc/update-motd.d/50-motd-news
chmod -x /etc/update-motd.d/90-updates-available
chmod -x /etc/update-motd.d/91-release-upgrade

# 3. Creacion del MOTD personalizado
cat << 'EOF' > /etc/update-motd.d/99-personalizado
#!/bin/bash

# Colores
NC='\033[0m'
CORAL='\033[38;5;203m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
WHITE='\033[1;37m'

# Datos del sistema
OS=$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2)
UPTIME=$(uptime -p | sed 's/up //')

INTERFACES_RAW=$(ip -o -4 addr show | grep -v " lo")
IFACE_COUNT=$(echo "$INTERFACES_RAW" | grep -c "^")
IFACE_DETAILS=$(echo "$INTERFACES_RAW" | awk '{print "    * "$2": "$4}' | cut -d/ -f1)

USERS_LOG=$(w -h | wc -l)
RAM_DATA=$(free -m | awk 'NR==2{printf "%s/%s MB (%.2f%%)", $3,$2,$3*100/$2 }')
DISK_DATA=$(df -h / | awk '$NF=="/"{printf "%s/%s (%s)", $3,$2,$5}')
LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')

if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP=$(awk '{printf "%.1f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp)
else
    TEMP="N/A (VM)"
fi

# Banner
echo -e "${CORAL}"
cat << 'BANNER'
░███     ░███           ░██████     ░███    ░██                   ░██
░████   ░████          ░██   ░██   ░██░██   ░██                 ░████
░██░██ ░██░██         ░██         ░██  ░██  ░██                   ░██
░██ ░████ ░██ ░██████ ░██  █████ ░█████████ ░██         ░██████   ░██
░██  ░██  ░██         ░██     ██ ░██    ░██ ░██                   ░██
░██       ░██          ░██  ░███ ░██    ░██ ░██                   ░██
░██       ░██           ░█████░█ ░██    ░██ ░██████████         ░██████
BANNER
echo -e "${NC}"

echo "====================================================================="
echo "========================== Proyecto 2ºASIR =========================="
echo "====================================================================="
echo -e "Sistema Operativo: ${WHITE}$OS${NC}"
echo -e "Red interfaces: ${CYAN}$IFACE_COUNT${NC}"
echo -e "${WHITE}$IFACE_DETAILS${NC}"
echo -e "Uptime:            ${GREEN}$UPTIME${NC}"
echo ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
echo "Estado de los recursos:"
echo -e " * RAM:       ${CYAN}$RAM_DATA${NC}"
echo -e " * DISCO (V): ${CYAN}$DISK_DATA${NC}"
echo -e " * CARGA CPU: ${CYAN}$LOAD${NC} (1, 5, 15 min)"
echo -e " * TEMP CPU:  ${CYAN}$TEMP${NC}"
echo -e " * SESIONES:  ${CYAN}$USERS_LOG${NC} activa(s)"
echo ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
echo ""
EOF

# Permisos de ejecucion para el MOTD
chmod +x /etc/update-motd.d/99-personalizado

echo "======================================================================"
echo " OPERACIÓN COMPLETADA"
echo "======================================================================"