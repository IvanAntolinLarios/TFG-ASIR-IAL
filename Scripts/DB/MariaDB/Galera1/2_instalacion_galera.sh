#!/bin/bash

# --- VARIABLES DE CONFIGURACIÓN ---
SST_USER="sst_user"
SST_PASS=""

if [ "$EUID" -ne 0 ]; then 
  echo "Por favor, usa sudo."
  exit 1
fi

# 1. Instalación de paquetes necesarios
apt update
apt install -y mariadb-server mariadb-client galera-4 apparmor-utils lsof socat mariadb-backup

# 2. Preparación de seguridad y directorios
systemctl stop mariadb
aa-complain /usr/sbin/mariadbd
rm -rf /var/lib/mysql/*
chown -R mysql:mysql /var/lib/mysql
mysql_install_db --user=mysql --datadir=/var/lib/mysql

# 3. Override de Systemd (Permisos avanzados para el proceso)
mkdir -p /etc/systemd/system/mariadb.service.d/
cat <<EOF > /etc/systemd/system/mariadb.service.d/override.conf
[Service]
ProtectSystem=off
ProtectHome=false
PrivateDevices=false
PrivateTmp=false
NoNewPrivileges=no
CapabilityBoundingSet=CAP_IPC_LOCK CAP_DAC_OVERRIDE CAP_NET_RAW CAP_SETGID CAP_SETUID CAP_SYS_RESOURCE CAP_CHOWN
LimitMEMLOCK=infinity
LimitNOFILE=65535
EOF

systemctl daemon-reload

# 4. Gestión de Certificados
# Suponiendo que estan en el home: ~/ca-cert.pem, ~/galera-node-cert.pem, ~/galera-node-key.pem
mkdir -p /etc/mysql/ssl
mv ~/ca-cert.pem /etc/mysql/ssl/
mv ~/galera-node-cert.pem /etc/mysql/ssl/
mv ~/galera-node-key.pem /etc/mysql/ssl/

chown -R mysql:mysql /etc/mysql/ssl
chmod 600 /etc/mysql/ssl/galera-node-key.pem
chmod 644 /etc/mysql/ssl/ca-cert.pem /etc/mysql/ssl/galera-node-cert.pem

# 5. Configuración de Galera
cat <<EOF > /etc/mysql/mariadb.conf.d/60-galera.cnf
[mariadb]
# CONFIGURACION BASE
bind-address=0.0.0.0
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2

# CONFIGURACION GALERA CLUSTER
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
wsrep_cluster_name="tfg_cluster"
wsrep_cluster_address="gcomm://192.168.45.51,192.168.45.52,192.168.45.53"
wsrep_sst_method=mariabackup
wsrep_sst_auth="$SST_USER:$SST_PASS"

# IDENTIDAD DEL NODO
port = 4401
wsrep_node_name="galera1"
wsrep_node_address="192.168.45.51"
wsrep_sst_receive_address="192.168.45.51:4444"

# SEGURIDAD SSL
ssl_ca="/etc/mysql/ssl/ca-cert.pem"
ssl_cert="/etc/mysql/ssl/galera-node-cert.pem"
ssl_key="/etc/mysql/ssl/galera-node-key.pem"

wsrep_provider_options="socket.ssl_ca=/etc/mysql/ssl/ca-cert.pem;socket.ssl_cert=/etc/mysql/ssl/galera-node-cert.pem;socket.ssl_key=/etc/mysql/ssl/galera-node-key.pem;socket.ssl=yes"

[sst]
# SEGURIDAD PARA TRANSFERENCIAS PESADAS
encrypt=4
ssl-ca=/etc/mysql/ssl/ca-cert.pem
ssl-cert=/etc/mysql/ssl/galera-node-cert.pem
ssl-key=/etc/mysql/ssl/galera-node-key.pem
EOF

echo "======================================================================"
echo " OPERACIÓN COMPLETADA"
echo "======================================================================"