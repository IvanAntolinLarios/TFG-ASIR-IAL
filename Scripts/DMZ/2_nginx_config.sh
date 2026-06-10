#!/bin/bash
if [ "$EUID" -ne 0 ]; then echo "Usa sudo"; exit 1; fi
USR=$(logname)

# 1. Instalación
apt update && apt install -y nginx

# 2. Organización de Certificados (Desde el home del usuario)
mkdir -p /etc/nginx/ssl
mv /home/$USR/ca-cert.pem /etc/nginx/ssl/
mv /home/$USR/proxy-frontend-cert.pem /etc/nginx/ssl/
mv /home/$USR/proxy-frontend-key.pem /etc/nginx/ssl/
chown -R root:root /etc/nginx/ssl
chmod 600 /etc/nginx/ssl/proxy-frontend-key.pem

# 3. Configuración del Proxy (Solo Puerto 443)
cat << 'EOF' > /etc/nginx/sites-available/tfg_proxy
# --- WEB TFG ---
server {
    # Escucha en el puerto 443 (HTTPS) y activa el protocolo moderno HTTP/2 para mayor velocidad
    listen 443 ssl;
    http2 on;
    
    # Define el dominio (Virtual Host) al que responderá este bloque
    server_name web.tfg.local;

    # Rutas de los certificados generados por nuestra PKI propia (Tramo Internet <-> DMZ)
    ssl_certificate /etc/nginx/ssl/proxy-frontend-cert.pem;
    ssl_certificate_key /etc/nginx/ssl/proxy-frontend-key.pem;

    # Bloque principal de proxy inverso
    location / {
        # Redirige el tráfico al nodo del Docker Swarm (VLAN 235) cifrando la conexión interna
        proxy_pass https://192.168.23.71:6550;
        
        # Inyección de cabeceras para preservar la identidad de la petición original
        proxy_set_header Host $host;                                 # Mantiene el dominio original
        proxy_set_header X-Real-IP $remote_addr;                     # Pasa la IP real del cliente al backend
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; # Cadena de IPs por si el paquete atraviesa más proxies
        proxy_set_header X-Forwarded-Proto $scheme;                  # Informa al backend que la conexión original entró por HTTPS
        
        # Desactiva la verificación estricta del certificado del backend 
        # (Necesario porque la conexión interna usa un certificado autofirmado por nuestra CA)
        proxy_ssl_verify off;
    }
}

# --- MOODLE ---

server {
    # Misma configuración base de seguridad que el sitio web
    listen 443 ssl;
    http2 on;
    server_name moodle.tfg.local;

    # Reutilizamos el certificado del frontend para este dominio
    ssl_certificate /etc/nginx/ssl/proxy-frontend-cert.pem;
    ssl_certificate_key /etc/nginx/ssl/proxy-frontend-key.pem;

    location / {
        # Redirige el tráfico al puerto específico del contenedor Moodle en el Swarm
        proxy_pass https://192.168.23.71:6551;
        
        # Cabeceras estándar de proxy inverso
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CABECERA CRÍTICA PARA MOODLE: Prevención de bucles infinitos
        # Moodle necesita saber explícitamente que el tráfico exterior entró por el puerto seguro 443
        proxy_set_header X-Forwarded-Port 443;
        
        proxy_ssl_verify off;
    }
}
EOF

# 4. Activar y Reiniciar
ln -s /etc/nginx/sites-available/tfg_proxy /etc/nginx/sites-enabled/ 2>/dev/null
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

echo "======================================================================"
echo " OPERACIÓN COMPLETADA"
echo "======================================================================"