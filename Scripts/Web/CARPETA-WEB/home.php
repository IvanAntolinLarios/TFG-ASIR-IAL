<?php 
// Incluimos la conexión para que se inicie la sesión
include_once '/var/www/html/resourses/db.php';

// Si el usuario no está logueado, lo mandamos al login
if (!isset($_SESSION['user_id'])) {
    header("Location: /login.php");
    exit();
}

include_once '/var/www/html/resourses/header.php'; 
?>

<div class="bg-white p-8 rounded border border-slate-200 shadow-sm max-w-2xl mx-auto">
    <h1 class="text-2xl font-bold mb-4">
        Hola, <span class="text-blue-600"><?php echo $_SESSION['username']; ?></span>.
    </h1>
    
    <p class="text-slate-600 mb-6">
        Has iniciado sesión correctamente en el sistema del TFG.
    </p>

    <div class="border-t pt-4">
        <a href="/logout.php" class="text-red-600 font-bold hover:underline">
            Cerrar sesión
        </a>
    </div>
</div>

<?php include_once '/var/www/html/resourses/footer.php'; ?>