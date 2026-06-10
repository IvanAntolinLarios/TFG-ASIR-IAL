<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Proyecto TFG</title>
    <link rel="icon" type="image/png" href="/img/favicon.png">
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-slate-50 text-slate-900 font-sans flex flex-col min-h-screen">

    <nav class="bg-slate-900 text-white p-4 shadow-2xl">
        <div class="container mx-auto flex justify-between items-center">
            <a href="/index.php" class="text-xl font-mono font-bold tracking-tighter text-blue-400">PROYECTO TFG</a>

            <div class="flex items-center space-x-4">
                <?php if (isset($_SESSION['user_id'])) { ?>
                    <div class="relative group">
                        <button class="bg-slate-800 px-4 py-2 rounded border border-slate-700 hover:bg-slate-700 transition">
                            <?php echo $_SESSION['username']; ?>
                        </button>
                        <div class="absolute right-0 w-48 bg-white text-slate-800 rounded shadow-2xl hidden group-hover:block z-50 mt-1 border border-slate-200">
                            <a href="/perfil.php?action=email" class="block px-4 py-2 hover:bg-slate-100 border-b">Cambiar Correo</a>
                            <a href="/perfil.php?action=password" class="block px-4 py-2 hover:bg-slate-100 border-b">Cambiar Contraseña</a>
                            <a href="/perfil.php?action=delete" class="block px-4 py-2 text-red-600 hover:bg-red-50 border-b">Borrar Cuenta</a>
                            <a href="/logout.php" class="block px-4 py-2 font-bold text-blue-600 hover:bg-slate-100">Cerrar Sesión</a>
                        </div>
                    </div>
                <?php } else { ?>
                    <a href="/login.php" class="bg-blue-600 hover:bg-blue-500 px-4 py-2 rounded transition">Iniciar Sesión</a>
                <?php } ?>
            </div>
        </div>
    </nav>

    <main class="flex-grow container mx-auto px-4 py-12">