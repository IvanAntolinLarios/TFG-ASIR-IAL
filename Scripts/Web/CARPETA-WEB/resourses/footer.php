</main>

    <footer class="bg-slate-100 border-t border-slate-200 py-8 mt-12">
        <div class="container mx-auto px-4 text-center">
            <div class="text-slate-500 text-sm mb-4">
                Contacto: <strong>admin@tfg.local</strong> | IES TRIANA | Sevilla, 2026
            </div>
            <div class="flex justify-center space-x-6 text-xs font-semibold text-slate-400">
                <a href="javascript:void(0)" onclick="abrirModal('cookies')" class="hover:text-blue-500 uppercase tracking-widest">Política de Cookies</a>
                <a href="javascript:void(0)" onclick="abrirModal('privacidad')" class="hover:text-blue-500 uppercase tracking-widest">Protección de Datos</a>
                <a href="javascript:void(0)" onclick="abrirModal('aviso')" class="hover:text-blue-500 uppercase tracking-widest">Aviso Legal</a>
            </div>
        </div>
    </footer>

    <div id="modalLegal" class="fixed inset-0 bg-black bg-opacity-50 hidden z-50 flex items-center justify-center p-4">
        <div class="bg-white rounded-lg max-w-2xl w-full p-6 shadow-2xl relative">
            <button onclick="cerrarModal()" class="absolute top-4 right-4 text-slate-400 hover:text-slate-600 font-bold text-xl">&times;</button>
            <h2 id="tituloLegal" class="text-xl font-bold mb-4 text-slate-800 uppercase"></h2>
            <div id="contenidoLegal" class="text-slate-600 text-sm leading-relaxed max-h-96 overflow-y-auto">
                </div>
        </div>
    </div>

    <script>
        const textos = {
            'cookies': {
                'titulo': 'Política de Cookies',
                'body': 'Este sitio utiliza únicamente cookies técnicas necesarias para mantener la sesión del usuario en la web. No se utilizan cookies de seguimiento ni de terceros.'
            },
            'privacidad': {
                'titulo': 'Protección de Datos',
                'body': 'Los datos personales (usuario y email) se almacenan de forma segura en un clúster de MariaDB Galera. Las contraseñas están cifradas y sus datos no serán cedidos a terceros.'
            },
            'aviso': {
                'titulo': 'Aviso Legal',
                'body': 'Este sitio web es un Proyecto Final de Grado (TFG) realizado en el IES Triana. Toda la infraestructura técnica (ProxySQL, Docker Swarm, Wireguard, etc.) ha sido configurada con fines educativos.'
            }
        };

        function abrirModal(tipo) {
            document.getElementById('tituloLegal').innerText = textos[tipo].titulo;
            document.getElementById('contenidoLegal').innerText = textos[tipo].body;
            document.getElementById('modalLegal').classList.remove('hidden');
        }

        function cerrarModal() {
            document.getElementById('modalLegal').classList.add('hidden');
        }

        // Cerrar si se hace clic fuera de la ventana blanca
        window.onclick = function(event) {
            let modal = document.getElementById('modalLegal');
            if (event.target == modal) {
                cerrarModal();
            }
        }
    </script>
</body>
</html>