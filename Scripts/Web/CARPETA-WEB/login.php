<?php
include_once '/var/www/html/resourses/db.php';

if (isset($_POST['enviar'])) {
    $usuario = $_POST['usuario'];
    $password = $_POST['password'];

    $sql = "SELECT id, username, password_hash FROM users WHERE username = '$usuario'";
    $resultado = mysqli_query($conn, $sql);
    $fila = mysqli_fetch_assoc($resultado);

    if ($fila && password_verify($password, $fila['password_hash'])) {
        $_SESSION['user_id'] = $fila['id'];
        $_SESSION['username'] = $fila['username'];
        header("Location: /home.php");
    } else {
        echo "<p style='color:red'>Usuario o contraseña incorrectos.</p>";
    }
}
include_once '/var/www/html/resourses/header.php';
?>

<div class="max-w-md mx-auto bg-white p-8 rounded border border-slate-200 shadow">
    <h2 class="text-2xl font-bold mb-6 text-slate-800">Identificación de Usuario</h2>
    <form method="POST" action="/login.php">
        <div class="mb-4">
            <label class="block text-slate-700 text-sm font-bold mb-2">Usuario:</label>
            <input type="text" name="usuario" class="w-full p-2 border rounded text-slate-800" required>
        </div>
        <div class="mb-6">
            <label class="block text-slate-700 text-sm font-bold mb-2">Contraseña:</label>
            <input type="password" name="password" class="w-full p-2 border rounded text-slate-800" required>
        </div>
        <button type="submit" name="enviar" class="w-full bg-blue-600 text-white font-bold py-2 px-4 rounded hover:bg-blue-700">
            ENTRAR
        </button>
    </form>
</div>

<?php include_once '/var/www/html/resourses/footer.php'; ?>