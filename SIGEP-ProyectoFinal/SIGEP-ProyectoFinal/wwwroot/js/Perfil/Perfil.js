
function calcularFechaMaxima() {
    const hoy = new Date();
    const año = hoy.getFullYear() - 17;
    const mes = String(hoy.getMonth() + 1).padStart(2, '0');
    const dia = String(hoy.getDate()).padStart(2, '0');
    return `${año}-${mes}-${dia}`;
}


function validarEdad(fechaNacimiento) {

    const partes = fechaNacimiento.split('-');
    const fecha = new Date(partes[0], partes[1] - 1, partes[2]);
    const hoy = new Date();

   
    hoy.setHours(0, 0, 0, 0);
    fecha.setHours(0, 0, 0, 0);

    let edad = hoy.getFullYear() - fecha.getFullYear();
    const mes = hoy.getMonth() - fecha.getMonth();

    if (mes < 0 || (mes === 0 && hoy.getDate() < fecha.getDate())) {
        edad--;
    }

    return edad >= 17;
}

document.addEventListener('DOMContentLoaded', function () {

    const encargado = document.getElementById('FormEncargado');

    encargado.addEventListener('submit', function (e) {
        e.preventDefault(); 
  
        const cedula = document.querySelector('[name="EstudianteEncargado.Cedula"]').value.trim();
        const nombre = document.querySelector('[name="EstudianteEncargado.Nombre"]').value.trim();
        const apellido1 = document.querySelector('[name="EstudianteEncargado.Apellido1"]').value.trim();
        const apellido2 = document.querySelector('[name="EstudianteEncargado.Apellido2"]').value.trim();
        const telefono = document.querySelector('[name="EstudianteEncargado.Telefono"]').value.trim();
        const parentesco = document.querySelector('[name="EstudianteEncargado.Parentesco"]').value.trim();
        const lugarTrabajo = document.querySelector('[name="EstudianteEncargado.LugarTrabajo"]').value.trim();
        const ocupacion = document.querySelector('[name="EstudianteEncargado.Ocupacion"]').value.trim();
        const correo = document.querySelector('[name="EstudianteEncargado.Correo"]').value.trim();


        if (!cedula || !nombre || !apellido1 || !telefono || !parentesco || !correo) {
            Swal.fire({
                icon: 'warning',
                title: 'Campos requeridos',
                text: 'Por favor complete todos los campos obligatorios (Cédula, Nombre, Primer Apellido, Teléfono, Parentesco y Correo).'
            });
            return;
        }

        const soloNumeros = telefono.replace(/[^0-9]/g, '');
        if (soloNumeros.length < 8) {
            Swal.fire({
                icon: 'warning',
                title: 'Teléfono inválido',
                text: 'El teléfono debe contener al menos 8 dígitos numéricos.'
            });
            return;
        }

        const regexCorreo = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!regexCorreo.test(correo)) {
            Swal.fire({
                icon: 'warning',
                title: 'Correo inválido',
                text: 'Por favor ingrese un correo electrónico válido.'
            });
            return;
        }

        Swal.fire({
            title: '¿Guardar encargado?',
            text: "Se guardará la información del encargado.",
            icon: 'question',
            showCancelButton: true,
            confirmButtonText: 'Sí, guardar',
            cancelButtonText: 'Cancelar'
        }).then((result) => {
            if (result.isConfirmed) {
                encargado.submit();
            }
        });

    });

    const formContrasenna = document.getElementById("ActualizarContrasenna");

    formContrasenna.addEventListener("submit", function (e) {
        e.preventDefault();


        let pass = document.getElementById("ContrasennaNueva").value.trim();
        let passConf = document.getElementById("ContrasennaNuevaPerfil").value.trim();

        if (pass.length < 8) {
            Swal.fire("Atención", "La contraseña debe tener al menos 8 caracteres.", "warning");
            return;
        }
        if (pass !== passConf) {
            Swal.fire("Error", "Las contraseñas no coinciden.", "error");
            return;
        }


        Swal.fire({
            title: "¿Deseas actualizar la contraseña?",
            icon: "question",
            showCancelButton: true,
            confirmButtonText: "Sí, actualizar",
            cancelButtonText: "Cancelar"
        }).then((result) => {
            if (result.isConfirmed) {
                formContrasenna.submit();
            }
        });

    });

    const formPerfil = document.getElementById('ActualizarPerfil');

    formPerfil.addEventListener('submit', function (e) {
       
        limpiarErrores();

        let esValido = true;
        let mensajesErrores = [];

      
        const nombre = document.getElementById('NombrePerfil');
        const apellido1 = document.getElementById('Apellido1Perfil');
        const apellido2 = document.getElementById('Apellido2Perfil');
        const cedula = document.getElementById('CedulaPerfil');
        const fechaNac = document.getElementById('FechaNacimientoPerfil');
        const telefono = document.getElementById('TelefonoPerfil');
        const correo = document.getElementById('CorreoPersonalPerfil');
        const sexo = document.getElementById('SexoPerfil'); 
        const nacionalidad = document.getElementById('NacionalidadPerfil');
        const provincia = document.getElementById('Provincia');
        const canton = document.getElementById('Canton');
        const distrito = document.getElementById('Distrito');
        const direccion = document.getElementById('DireccionPerfil');

       
        function marcarError(campo, mensaje) {
            esValido = false;
            mensajesErrores.push(mensaje);
            campo.classList.add('is-invalid');

            const spanError = document.createElement('div');
            spanError.classList.add('invalid-feedback');
            spanError.textContent = mensaje;

            const existente = campo.parentElement.querySelector('.invalid-feedback');
            if (existente) {
                existente.remove();
            }

            campo.parentElement.appendChild(spanError);
        }

        if (!nombre.value.trim()) {
            marcarError(nombre, 'El nombre es obligatorio.');
        }

        if (!apellido1.value.trim()) {
            marcarError(apellido1, 'El primer apellido es obligatorio.');
        }

        if (!apellido2.value.trim()) {
            marcarError(apellido2, 'El segundo apellido es obligatorio.');
        }

        if (!cedula.value.trim()) {
            marcarError(cedula, 'La cédula es obligatoria.');
        }

       
        if (!fechaNac.value) {
            marcarError(fechaNac, 'La fecha de nacimiento es obligatoria.');
        } else {
            const hoy = new Date();
            const fechaNacimiento = new Date(fechaNac.value);

            let edad = hoy.getFullYear() - fechaNacimiento.getFullYear();
            const mes = hoy.getMonth() - fechaNacimiento.getMonth();
            if (mes < 0 || (mes === 0 && hoy.getDate() < fechaNacimiento.getDate())) {
                edad--;
            }

            if (isNaN(edad)) {
                marcarError(fechaNac, 'La fecha de nacimiento no es válida.');
            } else if (edad < 17) {
                marcarError(fechaNac, 'Debes ser mayor de 17 años.');
            }
        }

        
        if (!telefono.value.trim()) {
            marcarError(telefono, 'El teléfono es obligatorio.');
        } else {
            const soloDigitos = telefono.value.replace(/\D/g, '');
            if (soloDigitos.length < 8) {
                marcarError(telefono, 'El teléfono debe tener al menos 8 dígitos.');
            }
        }

      
        if (!correo.value.trim()) {
            marcarError(correo, 'El correo electrónico es obligatorio.');
        } else {
            const regexCorreo = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!regexCorreo.test(correo.value.trim())) {
                marcarError(correo, 'El correo electrónico no tiene un formato válido.');
            }
        }

        
        if (!provincia.value || provincia.value === 'Seleccione una provincia') {
            marcarError(provincia, 'La provincia es obligatoria.');
        }

        if (!canton.value || canton.value === 'Seleccione un cantón') {
            marcarError(canton, 'El cantón es obligatorio.');
        }

        if (!distrito.value || distrito.value === 'Seleccione un distrito') {
            marcarError(distrito, 'El distrito es obligatorio.');
        }

      
        if (!direccion.value.trim()) {
            marcarError(direccion, 'La dirección exacta es obligatoria.');
        }

      
        if (!sexo.value) {
            marcarError(sexo, 'El sexo/género es obligatorio.');
        }

        if (!nacionalidad.value.trim()) {
            marcarError(nacionalidad, 'La nacionalidad es obligatoria.');
        }
        

        if (!esValido) {
            e.preventDefault();

          
            Swal.fire({
                icon: 'error',
                title: 'Revisa la información',
                html: '<ul style="text-align:left;">' +
                    mensajesErrores.map(m => `<li>${m}</li>`).join('') +
                    '</ul>',
                confirmButtonText: 'Aceptar'
            });
        } else {
          
            e.preventDefault(); 

            Swal.fire({
                icon: 'question',
                title: 'Confirmar actualización',
                text: '¿Deseas guardar los cambios en tu información personal?',
                showCancelButton: true,
                confirmButtonText: 'Sí, guardar',
                cancelButtonText: 'Cancelar'
            }).then((result) => {
                if (result.isConfirmed) {
                    form.submit(); 
                }
            });
        }
    });

    function limpiarErrores() {
        const camposInvalidos = document.querySelectorAll('#ActualizarPerfil .is-invalid');
        camposInvalidos.forEach(c => c.classList.remove('is-invalid'));

        const mensajes = document.querySelectorAll('#ActualizarPerfil .invalid-feedback');
        mensajes.forEach(m => m.remove());
    }


    const inputFecha = document.getElementById('FechaNacimientoPerfil');

    if (!inputFecha) return;

   
    inputFecha.max = calcularFechaMaxima();

  
    const añoMinimo = new Date().getFullYear() - 100;
    inputFecha.min = `${añoMinimo}-01-01`;

    inputFecha.addEventListener('change', function () {
        const fechaSeleccionada = this.value;

        if (!fechaSeleccionada) {
            this.setCustomValidity('Por favor, seleccione su fecha de nacimiento');
            return;
        }

        if (!validarEdad(fechaSeleccionada)) {
            this.setCustomValidity('Debe ser mayor de 17 años para registrarse');
            this.reportValidity();
        } else {
            this.setCustomValidity('');
        }
    });

    const form = inputFecha.closest('form');
    if (form) {
        form.addEventListener('submit', function (e) {
            const fechaSeleccionada = inputFecha.value;

            if (!fechaSeleccionada || !validarEdad(fechaSeleccionada)) {
                e.preventDefault();
                inputFecha.setCustomValidity('Debes tener al menos 17 años');
                inputFecha.reportValidity();
            }
        });
    }

   

  
});
  


