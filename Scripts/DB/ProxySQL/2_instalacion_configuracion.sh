#!/bin/bash

# --- VARIABLES DE SEGURIDAD (Credenciales del TFG) ---
MONITOR_PASS=""
ADMIN_CRED="admin:PASSWD"
STATS_CRED="test:PASSWD"
WEB_PASS=""
MOODLE_PASS=""
ADMIN_PASS_F_PROXY=""

if [ "$EUID" -ne 0 ]; then 
  echo "Por favor, usa sudo."
  exit 1
fi

# 1. INSTALACIÓN DEL SERVICIO
apt-get update
apt-get install -y --no-install-recommends lsb-release wget apt-transport-https ca-certificates gnupg mariadb-client

wget -nv -O /etc/apt/trusted.gpg.d/proxysql-3.0.x-keyring.gpg 'https://repo.proxysql.com/ProxySQL/proxysql-3.0.x/repo_pub_key.gpg'
echo "deb https://repo.proxysql.com/ProxySQL/proxysql-3.0.x/$(lsb_release -sc)/ ./" | tee /etc/apt/sources.list.d/proxysql.list

apt-get update
apt-get install -y proxysql

# 2. CONFIGURACIÓN INICIAL Y PUERTOS
systemctl stop proxysql
sed -i 's/interfaces="0.0.0.0:6033"/interfaces="0.0.0.0:7704"/' /etc/proxysql.cnf
rm -f /var/lib/proxysql/proxysql.db

# 3. GESTIÓN DE CERTIFICADOS SSL (PKI-KING)
# Suponiendo que están en el home del usuario
rm /var/lib/proxysql/proxysql-ca.pem 
rm /var/lib/proxysql/proxysql-cert.pem 
rm /var/lib/proxysql/proxysql-key.pem
mv ~/ca-cert.pem /var/lib/proxysql/proxysql-ca.pem
mv ~/proxysql-cert.pem /var/lib/proxysql/proxysql-cert.pem
mv ~/proxysql-key.pem /var/lib/proxysql/proxysql-key.pem

chown proxysql:proxysql /var/lib/proxysql/*.pem
chmod 644 /var/lib/proxysql/proxysql-ca.pem
chmod 644 /var/lib/proxysql/proxysql-cert.pem
chmod 600 /var/lib/proxysql/proxysql-key.pem

systemctl start proxysql
sleep 3 # Esperar a que inicialice la DB

# 4. CONFIGURACIÓN INTEGRAL (Vía SQL)
mysql -u admin -padmin -h 127.0.0.1 -P 6032 <<EOF
/* Red, SSL y Monitorización */
UPDATE global_variables SET variable_value='0.0.0.0:7704' WHERE variable_name='mysql-interfaces';
UPDATE global_variables SET variable_value='true' WHERE variable_name='mysql-have_ssl';
UPDATE global_variables SET variable_value='monitor' WHERE variable_name='mysql-monitor_username';
UPDATE global_variables SET variable_value='$MONITOR_PASS' WHERE variable_name='mysql-monitor_password';
UPDATE global_variables SET variable_value='true' WHERE variable_name='mysql-monitor_ssl';
UPDATE global_variables SET variable_value='11.4.0' WHERE variable_name='mysql-server_version';

/* Intervalos de Monitorización Agresivos (1s) */
UPDATE global_variables SET variable_value='1000' WHERE variable_name='mysql-monitor_connect_interval';
UPDATE global_variables SET variable_value='1000' WHERE variable_name='mysql-monitor_ping_interval';
UPDATE global_variables SET variable_value='1000' WHERE variable_name='mysql-monitor_galera_healthcheck_interval';

/* Definición del Clúster Galera */
INSERT INTO mysql_servers(hostgroup_id, hostname, port, use_ssl, weight) VALUES
(10, '192.168.45.51', 4401, 1, 1000), (10, '192.168.45.52', 4402, 1, 1000), (10, '192.168.45.53', 4403, 1, 1000),
(20, '192.168.45.51', 4401, 1, 1000), (20, '192.168.45.52', 4402, 1, 1000), (20, '192.168.45.53', 4403, 1, 1000);

INSERT INTO mysql_galera_hostgroups (writer_hostgroup, backup_writer_hostgroup, reader_hostgroup, offline_hostgroup, active, max_writers)
VALUES (10, 20, 30, 40, 1, 1);

/* Usuarios de Aplicación */
INSERT INTO mysql_users(username, password, default_hostgroup, use_ssl) VALUES
('web_tfg', '$WEB_PASS', 10, 1),
('moodle_user', '$MOODLE_PASS', 10, 0),
('admin_supremo', '$ADMIN_PASS_F_PROXY', 10, 1);

/* Reglas de Lectura/Escritura */
INSERT INTO mysql_query_rules (rule_id, active, match_digest, destination_hostgroup, apply) VALUES 
(100, 1, '^SELECT.* FOR UPDATE', 10, 1),
(101, 1, '^SELECT.*', 20, 1),
(200, 1, '.*', 10, 1);

/* Seguridad Administrativa */
UPDATE global_variables SET variable_value='$ADMIN_CRED' WHERE variable_name='admin-admin_credentials';
UPDATE global_variables SET variable_value='$STATS_CRED' WHERE variable_name='admin-stats_credentials';

/* Persistencia */
LOAD MYSQL VARIABLES TO RUNTIME; SAVE MYSQL VARIABLES TO DISK;
LOAD MYSQL SERVERS TO RUNTIME; SAVE MYSQL SERVERS TO DISK;
LOAD MYSQL USERS TO RUNTIME; SAVE MYSQL USERS TO DISK;
LOAD MYSQL QUERY RULES TO RUNTIME; SAVE MYSQL QUERY RULES TO DISK;
LOAD ADMIN VARIABLES TO RUNTIME; SAVE ADMIN VARIABLES TO DISK;
EOF

echo "======================================================================"
echo " OPERACIÓN COMPLETADA"
echo "======================================================================"