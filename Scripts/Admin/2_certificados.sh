#!/bin/bash

# 1. Creación de estructura de directorios
mkdir -p pki-cluster/{galera,web,proxy,proxysql}
cd pki-cluster

# 2. Generación de la CA (Root)
echo "Generando CA..."
openssl genrsa 2048 > ca-key.pem
openssl req -new -x509 -nodes -days 3650 -key ca-key.pem -out ca-cert.pem -subj "/CN=TFG-IAL-CA"

# Función para automatizar la creación de certificados de servicio
generate_service_cert() {
    local service=$1
    local name=$2
    local dir=$3

    echo "Generando certificado para $name..."
    openssl genrsa -out "$dir/$name-key.pem" 2048
    openssl req -new -key "$dir/$name-key.pem" -out "$dir/$name.csr" -subj "/CN=$name.tfg.local"
    openssl x509 -req -in "$dir/$name.csr" -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out "$dir/$name-cert.pem" -days 365 -sha256
}

# 3. Generación de certificados por servicio
generate_service_cert "galera" "galera-node" "galera"
generate_service_cert "web" "web" "web"
generate_service_cert "proxy" "proxy-frontend" "proxy"
generate_service_cert "proxysql" "proxysql" "proxysql"

echo "======================================================================"
echo " OPERACIÓN COMPLETADA: PKI generada con éxito en la carpeta pki-cluster/"
echo "======================================================================"
