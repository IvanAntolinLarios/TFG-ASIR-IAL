#!/bin/bash

# Comprobación de privilegios
if [ "$EUID" -ne 0 ]; then 
  echo "Error: Por favor, ejecuta este script usando sudo."
  exit 1
fi
# --- VARIABLES ---
PUBKEY_WORKER="PEGA_AQUI_LA_CLAVE_PÚBLICA__DE_WIREGUARD_DEL_WORKER"
USR=$(logname)
PROJECT_DIR="/home/$USR/tfg-web"
MOODLE_DB_PASSWD=""
MOODLE_USERNAME_PASSWD=""
# 1. Configurar WireGuard en el Manager
PRIVKEY_MANAGER=$(cat /etc/wireguard/privatekey)
cat << EOF > /etc/wireguard/wg0.conf
[Interface]
# La IP que tendrá el Manager dentro del túnel cifrado
Address = 10.99.0.1/24
# El puerto UDP que escuchará para el túnel (como en tu práctica)
ListenPort = 50281

PrivateKey = $PRIVKEY_MANAGER
MTU = 1280

[Peer]
PublicKey = $PUBKEY_WORKER
AllowedIPs = 10.99.0.2/32
EOF
systemctl enable --now wg-quick@wg0

# 2. Configurar Registro Inseguro (Uso de tee para evitar comillas escapadas)
cat << 'EOF' | sudo tee /etc/docker/daemon.json > /dev/null
{
  "insecure-registries": ["10.99.0.1:5000"],
  "registry-mirrors": ["https://mirror.gcr.io"]
}
EOF

sudo systemctl restart docker

# 3. Organizar Proyecto y Certificados
mkdir -p /home/$USR/tfg-web/certs
mv /home/$USR/*.pem /home/$USR/tfg-web/certs/
chown -R $USR:$USR /home/$USR/tfg-web
chmod 755 /home/$USR/tfg-web/certs
chmod 644 /home/$USR/tfg-web/certs/*.pem

# 4. Crear Docker Secrets
docker secret create web_cert /home/$USR/tfg-web/certs/web-cert.pem
docker secret create web_key /home/$USR/tfg-web/certs/web-key.pem
docker secret create ca_cert /home/$USR/tfg-web/certs/ca-cert.pem

# 5. Generar ficheros del proyecto (Dockerfiles, Compose, Apache)

### docker-compose.yaml

cat << EOF > /home/$USR/tfg-web/docker-compose.yml
version: '3.8'

services:
  registry:
    image: registry:2
    ports: ["5000:5000"]
    volumes:
      - registry_data:/var/lib/registry
    deploy:
      placement:
        constraints: [node.role == manager]

  portainer:
    image: portainer/portainer-ce:latest
    command:
      - --ssl
      - --sslcert
      - /run/secrets/web_cert
      - --sslkey
      - /run/secrets/web_key
    ports:
      - "9451:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    secrets:
      - web_cert
      - web_key
    deploy:
      placement:
        constraints: [node.role == manager]

  web_tfg:
    image: 10.99.0.1:5000/mi-web-tfg:latest
    ports: ["6550:6550"]
    volumes:
      - type: volume
        source: nfs_web_data
        target: /var/www/html
    # USAMOS SECRETS EN LUGAR DE BIND MOUNTS
    secrets:
      - source: web_cert
        target: /etc/apache2/ssl/web-cert.pem
      - source: web_key
        target: /etc/apache2/ssl/web-key.pem
      - source: ca_cert
        target: /etc/apache2/ssl/ca-cert.pem
    deploy:
      replicas: 2

  moodle:
    image: 10.99.0.1:5000/moodle-tfg:es
    ports: ["6551:8443"]
    environment:
      #- MOODLE_SKIP_INSTALL=yes         # Si ya está instalado, que no pierda tiempo
      - BITNAMI_DEBUG=true
      - MOODLE_DATABASE_HOST=192.168.45.49
      - MOODLE_DATABASE_PORT_NUMBER=7704
      - MOODLE_DATABASE_USER=moodle_user
      - MOODLE_DATABASE_PASSWORD=$MOODLE_DB_PASSWD
      - MOODLE_DATABASE_NAME=moodle_db
      - MOODLE_USERNAME=admin_tfg
      - MOODLE_PASSWORD=$MOODLE_USERNAME_PASSWD
      - MOODLE_LANGUAGE=es
      - MOODLE_SITE_URL=https://moodle.tfg.local:6551
      - MOODLE_REVERSE_PROXY=yes
      # SSL PARA APACHE
      - APACHE_ENABLE_HTTPS=yes
      - APACHE_HTTPS_PORT_NUMBER=8443
      - APACHE_CERTIFICATE_FILE=/opt/bitnami/apache/conf/bitnami/certs/tls.crt
      - APACHE_KEY_FILE=/opt/bitnami/apache/conf/bitnami/certs/tls.key
      - APACHE_CA_CERTIFICATE_FILE=/opt/bitnami/apache/conf/bitnami/certs/tls.ca
      # SSL PARA LA DB
      - MOODLE_DATABASE_USE_SSL=true
      - MOODLE_DATABASE_SSL_CA_FILE=/opt/bitnami/apache/conf/bitnami/certs/tls.ca
      - MOODLE_DATABASE_SSL_VERIFY_SERVER_CERT=false
      - MYSQL_CLIENT_EXTRA_FLAGS=--ssl-ca=/opt/bitnami/apache/conf/bitnami/certs/tls.ca --ssl --ssl-verify-server-cert=OFF
      - MARIADB_CLIENT_EXTRA_FLAGS=--ssl-ca=/opt/bitnami/apache/conf/bitnami/certs/tls.ca --ssl --ssl-verify-server-cert=OFF
    volumes:
      - type: volume
        source: nfs_moodle_data
        target: /bitnami/moodle
    secrets:
      # Los montamos en /certs/ para no romper la carpeta de Apache
      - source: ca_cert
        target: /opt/bitnami/apache/conf/bitnami/certs/tls.ca
      - source: web_cert
        target: /opt/bitnami/apache/conf/bitnami/certs/tls.crt
      - source: web_key
        target: /opt/bitnami/apache/conf/bitnami/certs/tls.key
    deploy:
      replicas: 1
secrets:
  web_cert:
    external: true
  web_key:
    external: true
  ca_cert:
    external: true

volumes:
  registry_data: {}
  portainer_data: {}
  nfs_web_data:
    driver: local
    driver_opts:
      type: nfs
      o: "addr=10.99.0.1,nolock,soft,rw"
      device: ":/var/nfs_tfg/web"
  nfs_moodle_data:
    driver: local
    driver_opts:
      type: nfs
      o: "addr=10.99.0.1,nolock,soft,rw"
      device: ":/var/nfs_tfg/moodle_data"

networks:
  default:
    driver: overlay
    driver_opts:
      com.docker.network.driver.mtu: "1230"
EOF

### Dockerfile: Web_tfg
cat << 'EOF' > /home/$USR/tfg-web/Dockerfile.web_tfg
# Usamos una imagen oficial de PHP con Apache
FROM php:8.2-apache

# Instalamos las extensiones necesarias para MySQL/MariaDB
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Habilitamos el módulo SSL de Apache y el de reescritura
RUN a2enmod ssl && a2enmod rewrite

# Creamos el directorio para los certificados
RUN mkdir -p /etc/apache2/ssl

# Copiamos la configuración personalizada de Apache (se creara luego)
COPY ./apache-ssl.conf /etc/apache2/sites-available/000-default.conf

# Ajustamos permisos para que Apache pueda leer los archivos
RUN chown -R www-data:www-data /var/www/html

# Exponemos el puerto 6550
EXPOSE 6550
EOF

### Dockerfile: moodle
cat << 'EOF' > /home/$USR/tfg-web/Dockerfile.moodle
# Usamos la imagen de Bitnami como base
FROM public.ecr.aws/bitnami/moodle:latest

# Cambiamos a root para instalar paquetes
USER root

# 1. Limpiamos y preparamos locales
# 2. Descomentamos la línea de es_ES.UTF-8 en el archivo de configuración
# 3. Generamos los locales
RUN apt-get update && apt-get install -y locales && \
    sed -i 's/# es_ES.UTF-8 UTF-8/es_ES.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen es_ES.UTF-8

# Configuramos las variables de entorno directamente
# (Es más seguro que update-locale en Docker)
ENV LANG=es_ES.UTF-8
ENV LANGUAGE=es_ES:es
ENV LC_ALL=es_ES.UTF-8

# Volvemos al usuario de Bitnami
USER 1001
EOF

###apache-ssl.conf

cat << 'EOF' > /home/$USR/tfg-web/apache-ssl.conf
# Ocultar la firma del servidor (Seguridad por oscuridad)
ServerTokens Prod
ServerSignature Off

<VirtualHost *:6550>
    DocumentRoot /var/www/html
    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/web-cert.pem
    SSLCertificateKeyFile /etc/apache2/ssl/web-key.pem
    SSLCACertificateFile /etc/apache2/ssl/ca-cert.pem

    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>

    # Denegar acceso a archivos que no quiero mostrar abiertamente
    <Directory "/var/www/html/resourses">
	      Options -Indexes
        AllowOverride None
        Require all denied
    </Directory>

    <Directory "/var/www/html/img">
        Options -Indexes
        AllowOverride None
    </Directory>
    
    ErrorDocument 404 /404.php

</VirtualHost>

# Necesitamos decirle a Apache que escuche en el 6550
Listen 6550
EOF

# 6. Despliegue
cd /home/$USR/tfg-web
docker stack deploy -c docker-compose.yml mi_proyecto
sleep 15
# Construir y subir imágenes al Registry local (10.99.0.1)
docker build -t 10.99.0.1:5000/mi-web-tfg:latest -f Dockerfile.web_tfg .
docker push 10.99.0.1:5000/mi-web-tfg:latest
docker build -t 10.99.0.1:5000/moodle-tfg:es -f Dockerfile.moodle .
docker push 10.99.0.1:5000/moodle-tfg:es
# Relanzar el Stack para aplicar las imágenes personalizadas
docker stack deploy -c docker-compose.yml mi_proyecto

echo "======================================================================"
echo " OPERACIÓN COMPLETADA"
echo "======================================================================"
# ==================================================================
# CHULETA DE GESTIÓN DEL DOCKER SWARM
# ==================================================================
echo "              GUÍA DE GESTIÓN"
echo "======================================================================"
echo "ESTADO DEL CLÚSTER:"
echo "  - Ver nodos:           docker node ls"
echo "  - Ver servicios:       docker stack services mi_proyecto"
echo "  - Ver contenedores:    docker stack ps mi_proyecto"
echo ""
echo "GESTIÓN DE CONTENEDORES:"
echo "  - Logs en vivo (Web):  docker service logs -f mi_proyecto_web_tfg"
echo "  - Forzar reinicio:     docker service update --force mi_proyecto_web_tfg"
echo ""
echo "SEGURIDAD Y RED:"
echo "  - Ver secretos:        docker secret ls"
echo "  - Ver túnel VPN:       wg show"
echo "  - Ver red Overlay:     docker network inspect mi_red_swarm"
echo ""
echo "ACTUALIZACIÓN:"
echo "  - Si cambias el código, vuelve a ejecutar el paso de 'build' y 'push'"
echo "======================================================================"