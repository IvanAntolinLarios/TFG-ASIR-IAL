#!/bin/bash

# Comprobacion de privilegios root
if [ "$EUID" -ne 0 ]; then 
  echo "Error: Por favor, ejecuta este script usando sudo."
  exit 1
fi

sudo ufw default deny incoming 
sudo ufw default allow outgoing 
sudo ufw --force enable 
sudo ufw status verbose

echo "======================================================================"
echo " OPERACIÓN COMPLETADA"
echo "======================================================================"