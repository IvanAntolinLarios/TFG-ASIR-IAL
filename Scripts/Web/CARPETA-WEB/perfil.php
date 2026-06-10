<?php
include_once '/var/www/html/resourses/db.php';

// Si no hay sesión, al login
if (!isset($_SESSION['user_id'])) {
    header("Location: /login.php");
    exit();
}

$id_usuario = $_SESSION['user_id'];
$mensaje = "";

// --- LOGICA PARA PROCESAR LOS CAMBIOS (POST) ---

// 1. Cambio de Email
if (isset($_POST['cambiar_email'])) {
    $nuevo_email = $_POST['email'];
    $sql = "UPDATE users SET email = '$nuevo_email' WHERE id = '$id_usuario'";
    if (mysqli_query($conn, $sql)) {
        $mensaje = "<p style='color:green'>Email actualizado correctamente.</p>";
    }
}

// 2. Cambio de Contraseña
if (isset($_POST['cambiar_pass'])) {
    $nueva_pass = password_hash($_POST['password'], PASSWORD_BCRYPT);
    $sql = "UPDATE users SET password_hash = '$nueva_pass' WHERE id = '$id_usuario'";
    if (mysqli_query($conn, $sql)) {
        $mensaje = "<p style='color:green'>Contraseña actualizada correctamente.</p>";
    }
}

// 3. Borrar Cuenta
if (isset($_POST['borrar_cuenta'])) {
    $sql = "DELETE FROM users WHERE id = '$id_usuario'";
    if (mysqli_query($conn, $sql)) {
        session_destroy();
        header("Location: /index.php");
        exit();
    }
}

include_once '/var/www/html/resourses/header.php';
?>

<div class="max-w-xl mx-auto bg-white p-8 rounded border border-slate-200 shadow-sm">
    <h1 class="text-2xl font-bold mb-6 text-slate-800">Gestión de Perfil</h1>
    
    <?php echo $mensaje; ?>

    <?php if ($_GET['action'] == 'email') { ?>
        <form method="POST" action="/perfil.php?action=email">
            <label class="block mb-2 font-bold text-slate-700">Nuevo Correo Electrónico:</label>
            <input type="email" name="email" class="w-full p-2 border rounded mb-4 text-slate-800" required>
            <button type="submit" name="cambiar_email" class="bg-blue-600 text-white px-4 py-2 rounded font-bold hover:bg-blue-700">
                ACTUALIZAR EMAIL
            </button>
        </form>

    <?php } elseif ($_GET['action'] == 'password') { ?>
        <form method="POST" action="perfil.php?action=password">
            <label class="block mb-2 font-bold text-slate-700">Nueva Contraseña:</label>
            <input type="password" name="password" class="w-full p-2 border rounded mb-4 text-slate-800" required>
            <button type="submit" name="cambiar_pass" class="bg-blue-600 text-white px-4 py-2 rounded font-bold hover:bg-blue-700">
                ACTUALIZAR CONTRASEÑA
            </button>
        </form>

    <?php } elseif ($_GET['action'] == 'delete') { ?>
        <div class="bg-red-50 p-6 border border-red-200 rounded">
            <h2 class="text-red-700 font-bold mb-2">Zona Peligrosa</h2>
            <p class="text-red-600 mb-4 text-sm">Esta acción es permanente y no se podrá deshacer.</p>
            <form method="POST" action="/perfil.php?action=delete">
                <button type="submit" name="borrar_cuenta" class="bg-red-600 text-white px-4 py-2 rounded font-bold hover:bg-red-700">
                    BORRAR MI CUENTA DEFINITIVAMENTE
                </button>
            </form>
        </div>
    <?php } ?>

    <div class="mt-8 border-t pt-4">
        <a href="/home.php" class="text-blue-600 hover:underline">Volver al panel</a>
    </div>
</div>

<?php include_once '/var/www/html/resourses/footer.php'; ?>