<?php 
include_once '/var/www/html/resourses/db.php'; 
include_once '/var/www/html/resourses/header.php'; 
?>

<div class="bg-white p-8 rounded-xl shadow-sm border border-slate-200 max-w-4xl mx-auto">
    <?php if (isset($_SESSION['username'])) { ?>
        <h1 class="text-3xl font-bold mb-4">Bienvenido al sistema, <span class="text-blue-600"><?php echo $_SESSION['username']; ?></span></h1>
    <?php } else { ?>
        <h1 class="text-3xl font-bold mb-4">Arquitectura de Seguridad y Alta Disponibilidad</h1>
    <?php } ?>

    <p class="text-slate-600 mb-8 leading-relaxed text-justify">
        Este proyecto implementa un entorno de red basado en el modelo de seguridad perimetral utilizando <strong>Docker Swarm</strong>. 
        La capa de datos está protegida por un balanceador <strong>ProxySQL</strong> y un clúster <strong>MariaDB Galera</strong>, 
        garantizando cifrado <strong>SSL/TLS</strong> y disponibilidad continua.
    </p>

    <?php if (!isset($_SESSION['user_id'])) { ?>
        <div class="flex justify-center mb-8">
            <a href="/register.php" class="border-2 border-blue-600 text-blue-600 px-12 py-3 rounded font-bold hover:bg-blue-50 transition">
                Crear cuenta
            </a>
        </div>
    <?php } ?>

    <div class="grid md:grid-cols-2 gap-6 mt-8">
        <div class="p-6 bg-slate-50 rounded-lg border-l-4 border-blue-500">
            <h3 class="font-bold text-slate-800">Infraestructura Crítica</h3>
            <p class="text-sm text-slate-500 mt-2">Despliegue de nodos mediante túneles VPN Wireguard y almacenamiento NFS centralizado.</p>
        </div>
        <div class="p-6 bg-slate-50 rounded-lg border-l-4 border-green-500">
            <h3 class="font-bold text-slate-800">Capa de Persistencia</h3>
            <p class="text-sm text-slate-500 mt-2">Base de datos redundante con replicación síncrona y gestión de secretos para llaves TLS.</p>
        </div>
    </div>
</div>

<?php include_once '/var/www/html/resourses/footer.php'; ?>