## Guía de Despliegue (Orden de Ejecución)

Para garantizar la integridad de la infraestructura y evitar errores de dependencias (especialmente con los certificados SSL y la conectividad de red), se debe seguir este orden estrictamente:

---

# IMPORTANTE: CONFIGURACION DE LAS MAQUINAS

Las maquinas estaran todas en una red interna (salvo la primera interfaz del router por supuesto) con el "PROMISCUOUS MODE" en modo "Permitir MVs" sino, no funcionara el trafico de VLAN

<img width="556" height="265" alt="image" src="https://github.com/user-attachments/assets/d4763aff-249d-4c34-ac89-ed3ef33e6748" />

---

### Fase I: Seguridad y Criptografía (Nodo KING)
**Scripts:** `0_preparacion.sh` hasta `3_ssh_client.sh` y `5_firewall.sh`
* **Acción:** Generación de la Autoridad de Certificación (CA) y los certificados `.pem` para todos los servicios.
* **Justificación:** El resto de los nodos (Galera, ProxySQL, Nginx, Swarm) requieren estos archivos para habilitar TLS/SSL desde el primer arranque.

---

### Fase II: Networking y Segmentación (ROUTER)
**Scripts:** `FULL` (Netplan + IPTables)
* **Acción:** Creación de las VLANs (DMZ, DB, WEB, MGMT) y reglas de Forwarding.
* **Justificación:** Establece las "carreteras" de comunicación. Sin el Router, los nodos no pueden comunicarse entre VLANs ni salir a Internet para descargar dependencias.

---

### Fase III: Herramientas de Gestión (Nodo KING)
**Scripts:** `4_herramientas.sh`
* **Acción:** Instalación de VS Code, Beekeeper Studio y KeePassXC.
* **Justificación:** Proporciona la interfaz necesaria para administrar las bases de datos y los secretos en las fases siguientes.

---

### Fase IV: Capa de Datos (GALERA CLUSTER & PROXYSQL)
**Scripts:**  PRIMERO:`FULL DB/GALERAX` (en nodos .51, .52, .53) --> SEGUNDO:`FULL DB/PROXYSQL`
* **Acción:**
    1. Levantar el clúster MariaDB Galera (Bootstrap en el primer nodo).
    2. Configurar ProxySQL para monitorizar y balancear el tráfico SQL.
* **Justificación:** Moodle y la Web corporativa necesitan un punto final (Endpoint) de base de datos operativo para poder arrancar.

---

### Fase V: Cómputo y Almacenamiento (DOCKER SWARM & NFS)
**Scripts:** PRIMERO:`0_personalizacion.sh` y `1_red_y_seguridad.sh` en ambas --> SEGUNDO:`MANAGER/2_servicios_manager.sh` --> TERCERO:`WORKER/2_servicios_worker.sh` --> CUEARTO:`MANAGER/3_docker_compose.sh` --> ULTIMO:`firewall.sh`
* **Acción:**
    1. Unir Manager y Worker al clúster Swarm.
    2. Levantar el túnel **WireGuard** para securizar el tráfico NFS.
    3. Desplegar el Stack de servicios (Moodle + Web).
* **Justificación:** El almacenamiento persistente (NFS) debe viajar por la VPN antes de que los contenedores intenten montar sus volúmenes.

---

### Fase VI: Publicación y Proxy (DMZ)
**Scripts:** `FULL`
* **Acción:** Configuración del Proxy Inverso con endurecimiento SSL (Solo puerto 443).
* **Justificación:** Es el paso final. Una vez que el backend (Swarm) es estable, abrimos la puerta al tráfico exterior de forma segura.
