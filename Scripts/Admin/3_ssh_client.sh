#!/bin/bash

# --- VARIABLES DE USUARIO (Rellenar antes de ejecutar) ---
U_ROUTER="U_ROUTER"
U_PROXY="U_PROXY"
U_WEB_M="U_WEB_M"
U_WEB_W="U_WEB_W"
U_PSQL="U_PSQL"
U_GALERA1="U_GALERA1"
U_GALERA2="U_GALERA2"
U_GALERA3="U_GALERA3"

# Crear/Limpiar el archivo config
mkdir -p ~/.ssh
cat << EOF > ~/.ssh/config
################################################
################### GATEWAY ####################
################################################
Host router
    HostName 192.168.137.1
    User $U_ROUTER
    Port 2137

################################################
################## VLAN: DMZ ###################
################################################
Host proxyhttps
    HostName 192.168.12.49
    User $U_PROXY
    Port 2371

################################################
################## VLAN: WEB ###################
################################################
Host d_manager
    HostName 192.168.23.71
    User $U_WEB_M
    Port 2235

Host d_worker1
    HostName 192.168.23.21
    User $U_WEB_W
    Port 2235

################################################
################# VLAN: DATOS ##################
################################################
Host proxysql
    HostName 192.168.45.49
    User $U_PSQL
    Port 2313

Host galera1
    HostName 192.168.45.51
    User $U_GALERA1
    Port 2313

Host galera2
    HostName 192.168.45.52
    User $U_GALERA2
    Port 2313

Host galera3
    HostName 192.168.45.53
    User $U_GALERA3
    Port 2313
EOF

chmod 600 ~/.ssh/config

echo "======================================================================"
echo " OPERACIÓN COMPLETADA: Archivo ~/.ssh/config generado y funcional"
echo "======================================================================"