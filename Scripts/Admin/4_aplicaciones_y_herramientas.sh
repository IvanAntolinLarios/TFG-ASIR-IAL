#!/bin/bash

# Comprobación de privilegios root
if [ "$EUID" -ne 0 ]; then 
  echo "Error: Por favor, ejecuta este script usando sudo."
  exit 1
fi

# 1. KeePassXC
apt update && apt install keepassxc -y

# 2. Visual Studio Code (Instalación limpia con repo oficial)
apt install wget gpg apt-transport-https -y

# Descargar y configurar la llave
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft-archive-keyring.gpg > /dev/null

# Configurar el repositorio usando TEE para evitar el "Permiso denegado"
echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

# Instalar
apt update && apt install code -y

# 3. Beekeeper Studio
# Lo descargamos a /tmp para no ensuciar el home
FILE_NAME="beekeeper-studio_5.7.2_amd64.deb"
wget "https://github.com/beekeeper-studio/beekeeper-studio/releases/download/v5.7.2/$FILE_NAME" -O "/tmp/$FILE_NAME"

# Instalamos desde la ruta temporal
apt install "/tmp/$FILE_NAME" -y

# Limpiamos al final
rm "/tmp/$FILE_NAME"

echo "=================================================="
echo " INSTALACIÓN COMPLETADA "
echo "=================================================="