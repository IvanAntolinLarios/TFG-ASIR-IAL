#!/bin/bash

# --- VARIABLES DE SEGURIDAD (Rellenar) ---
DB_ROOT_PASS=""
SST_USER="sst_user"
SST_PASS=""

# Usuarios de Aplicación/Gestión
MONITOR_PASS=""
WEB_PASS=""
MOODLE_PASS=""
ADMIN_PASS_F_PROXY=""
ADMIN_PASS_F_KING=""

# IPs de confianza
IP_PROXYSQL="192.168.45.49"
IP_KING="192.168.137.117"

if [ "$EUID" -ne 0 ]; then 
  echo "Por favor, usa sudo."
  exit 1
fi

echo "=================================================="
echo "   MARIADB GALERA - GESTIÓN DE LANZAMIENTO"
echo "=================================================="
echo "1) Lanzar NUEVO CLÚSTER (Solo Galera 1)"
echo "2) Unirse a clúster existente (Galera 2 y 3)"
read -p "Selecciona una opción: " OPCION

if [ "$OPCION" == "1" ]; then
    echo "[+] Preparando Galera 1 como Líder..."
    
    # Forzar estado de bootstrap
    DB_PATH="/var/lib/mariadb"
    
    echo "safe_to_bootstrap: 1" > "$DB_PATH/grastate.dat"
    chown mysql:mysql "$DB_PATH/grastate.dat"

    # Lanzar el clúster
    galera_new_cluster
    sleep 5

    echo "[+] Ejecutando Secure Installation..."
    # 1. Contraseña actual (vacía al instalar) -> Enter
    # 2. Switch to unix_socket? -> n
    # 3. Change root password? -> Y
    # 4. Nueva password -> $DB_ROOT_PASS
    # 5. Repetir password -> $DB_ROOT_PASS
    # 6. Remove anonymous users? -> Y
    # 7. Disallow root login remotely? -> Y
    # 8. Remove test database? -> Y
    # 9. Reload privilege tables? -> Y
    mariadb-secure-installation <<EOF

n
Y
$DB_ROOT_PASS
$DB_ROOT_PASS
Y
Y
Y
Y
EOF

    echo "[+] Creando base de datos y usuarios (Zero Trust)..."
    
    # Creamos un script SQL temporal
    cat <<EOF > /tmp/setup_users.sql
-- 1. Usuario SST (Replicación interna)
CREATE USER '$SST_USER'@'localhost' IDENTIFIED BY '$SST_PASS';
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO '$SST_USER'@'localhost';

-- 2. Usuario Monitor (Para los healthchecks del ProxySQL)
CREATE USER 'monitor'@'$IP_PROXYSQL' IDENTIFIED BY '$MONITOR_PASS';
GRANT USAGE, REPLICATION CLIENT ON *.* TO 'monitor'@'$IP_PROXYSQL';

-- 3. Bases de datos del proyecto
CREATE DATABASE IF NOT EXISTS db_tfg;
CREATE DATABASE IF NOT EXISTS moodle_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
SET GLOBAL innodb_default_row_format = 'dynamic';

-- 4. Usuario Web TFG
CREATE USER 'web_tfg'@'$IP_PROXYSQL' IDENTIFIED BY '$WEB_PASS';
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON db_tfg.* TO 'web_tfg'@'$IP_PROXYSQL';

-- 5. Usuario Moodle
CREATE USER 'moodle_user'@'$IP_PROXYSQL' IDENTIFIED BY '$MOODLE_PASS';
GRANT ALL PRIVILEGES ON moodle_db.* TO 'moodle_user'@'$IP_PROXYSQL';

-- 6. Admin Supremo (Desde ProxySQL - Acceso Total)
CREATE USER 'admin_supremo'@'$IP_PROXYSQL' IDENTIFIED BY '$ADMIN_PASS_F_PROXY';
GRANT ALL PRIVILEGES ON *.* TO 'admin_supremo'@'$IP_PROXYSQL' WITH GRANT OPTION;

-- 7. Admin Gestión (Desde KING - Lectura y Gestión de Usuarios)
-- No tiene permisos de escritura de datos, pero puede gestionar la plataforma
CREATE USER 'admin_supremo'@'$IP_KING' IDENTIFIED BY '$ADMIN_PASS_F_KING';
GRANT SELECT, SHOW DATABASES, CREATE USER, GRANT OPTION, PROCESS ON *.* TO 'admin_supremo'@'$IP_KING';

FLUSH PRIVILEGES;
EOF

    # Ejecutar el SQL
    mariadb -u root -p"$DB_ROOT_PASS" < /tmp/setup_users.sql
    rm /tmp/setup_users.sql

    echo ">>> Galera 1 lanzado y configurado correctamente."

elif [ "$OPCION" == "2" ]; then
    echo "[+] Uniendo nodo al clúster..."
    systemctl start mariadb
    echo ">>> Nodo unido. Verifica el estado con 'mariadb -u root -p"$DB_ROOT_PASS" -e \"show status like 'wsrep_cluster_size'\"'"
else
    echo "Opción no válida."
fi
