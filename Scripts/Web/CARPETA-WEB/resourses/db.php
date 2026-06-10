<?php
// Iniciamos la sesión para toda la web
session_start();

$host = '192.168.45.49';
$port = 7704;
$user = 'web_tfg';
$pass = '';
$db   = 'db_tfg';

$conn = mysqli_init();

// Configuramos el certificado para el túnel SSL hacia el ProxySQL
mysqli_ssl_set($conn, NULL, NULL, '/etc/apache2/ssl/ca-cert.pem', NULL, NULL);

// Intentamos conectar
$conexion = mysqli_real_connect($conn, $host, $user, $pass, $db, $port, NULL, MYSQLI_CLIENT_SSL);

// Si falla la conexión, mostramos el error técnico
if (!$conexion) {
    die("Error de conexion con el proxy/db: " . mysqli_connect_error());
}
?>
