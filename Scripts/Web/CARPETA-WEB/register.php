<?php
include_once '/var/www/html/resourses/db.php';
include_once '/var/www/html/resourses/header.php';

if (isset($_POST['registrar'])) {
    $usuario = $_POST['usuario'];
    $email = $_POST['email'];
    // Ciframos la contraseña antes de guardarla
    $pass_cifrada = password_hash($_POST['password'], PASSWORD_BCRYPT);

    $sql = "INSERT INTO users (username, email, password_hash) VALUES ('$usuario', '$email', '$pass_cifrada')";
    
    if (mysqli_query($conn, $sql)) {
        echo "<p style='color:green'>Usuario registrado con éxito. Ya puedes iniciar sesión.</p>";
    } else {
        echo "<p style='color:red'>Error al registrar: " . mysqli_error($conn) . "</p>";
    }
}
?>

<div class="max-w-md mx-auto bg-white p-8 rounded border border-slate-200 shadow">
    <h2 class="text-2xl font-bold mb-6 text-slate-800">Registro de Nuevo Usuario</h2>
    <form method="POST" action="/register.php">
        <div class="mb-4">
            <label class="block text-slate-700 text-sm font-bold mb-2">Nombre de Usuario:</label>
            <input type="text" name="usuario" class="w-full p-2 border rounded text-slate-800" required>
        </div>
        <div class="mb-4">
            <label class="block text-slate-700 text-sm font-bold mb-2">Email:</label>
            <input type="email" name="email" class="w-full p-2 border rounded text-slate-800" required>
        </div>
        <div class="mb-6">
            <label class="block text-slate-700 text-sm font-bold mb-2">Contraseña:</label>
            <input type="password" name="password" class="w-full p-2 border rounded text-slate-800" required>
        </div>
        <button type="submit" name="registrar" class="w-full bg-green-600 text-white font-bold py-2 px-4 rounded hover:bg-green-700">
            REGISTRAR
        </button>
    </form>
</div>

<?php include_once '/var/www/html/resourses/footer.php'; ?>