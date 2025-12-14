document.addEventListener("DOMContentLoaded", function () {
    const errorMsg = document.getElementById("TempError")?.value;
    const successMsg = document.getElementById("TempSuccess")?.value;

    if (errorMsg) {
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: errorMsg,
            confirmButtonColor: '#2D594D'
        });
    } else if (successMsg) {
        Swal.fire({
            icon: 'success',
            title: 'Éxito',
            text: successMsg,
            confirmButtonColor: '#2D594D'
        });
    }

    document.querySelectorAll('.toggle-password').forEach(icon => {
        icon.addEventListener('click', function () {

            const input = this.parentElement.querySelector('input');

            if (input.type === "password") {
                input.type = "text";
                this.classList.remove('fa-eye-slash');
                this.classList.add('fa-eye');
            } else {
                input.type = "password";
                this.classList.remove('fa-eye');
                this.classList.add('fa-eye-slash');
            }
        });
    });

    const iconoFecha = document.getElementById('IconoFechaNacimiento');
    const inputFecha = document.getElementById('FechaNacimientoRegistro');

    if (iconoFecha && inputFecha) {
        iconoFecha.style.cursor = 'pointer';

        iconoFecha.addEventListener('click', function () {

            if (typeof inputFecha.showPicker === 'function') {
                inputFecha.showPicker();
            } else {

                inputFecha.focus();
                inputFecha.click();
            }
        });
    }

    const form = document.getElementById("RegistroForm");

    form.addEventListener("submit", function (e) {
        e.preventDefault(); 

        let cedula = document.getElementById("CedulaRegistro").value.trim();
        let nombre = document.getElementById("NombreRegistro").value.trim();
        let apellido1 = document.getElementById("Apellido1Registro").value.trim();
        let apellido2 = document.getElementById("Apellido2Registro").value.trim();
        let especialidad = document.getElementById("EspecialidadRegistro").value;
        let seccion = document.getElementById("SeccionRegistro").value;
        let correo = document.getElementById("CorreoRegistro").value.trim();
        let fechaNac = document.getElementById("FechaNacimientoRegistro").value;
        let pass = document.getElementById("ContrasennaRegistro").value.trim();
        let passConf = document.getElementById("ContrasennaConfirmar").value.trim();

        if (fechaNac) {
            let fechaNacimiento = new Date(fechaNac);
            let hoy = new Date();

            let edad = hoy.getFullYear() - fechaNacimiento.getFullYear();
            let mes = hoy.getMonth() - fechaNacimiento.getMonth();


            if (mes < 0 || (mes === 0 && hoy.getDate() < fechaNacimiento.getDate())) {
                edad--;
            }

            if (edad < 17) {
                Swal.fire({
                    icon: 'error',
                    title: 'Edad no válida',
                    text: 'El estudiante debe tener al menos 17 años cumplidos.',
                    confirmButtonText: 'Entendido'
                });
                return false;
            }
        }

        if (cedula === "") {
            Swal.fire("Atención", "La cédula es obligatoria.", "warning");
            return;
        }
        if (nombre === "") {
            Swal.fire("Atención", "El nombre es obligatorio.", "warning");
            return;
        }
        if (apellido1 === "" || apellido2 === "") {
            Swal.fire("Atención", "Ambos apellidos son obligatorios.", "warning");
            return;
        }
        if (especialidad === "") {
            Swal.fire("Atención", "Seleccione una especialidad.", "warning");
            return;
        }
        if (seccion === "") {
            Swal.fire("Atención", "Seleccione una sección.", "warning");
            return;
        }
        if (correo === "") {
            Swal.fire("Atención", "El correo electrónico es obligatorio.", "warning");
            return;
        }
        if (!correo.includes("@")) {
            Swal.fire("Error", "Ingrese un correo válido.", "error");
            return;
        }
        if (fechaNac === "") {
            Swal.fire("Atención", "La fecha de nacimiento es obligatoria.", "warning");
            return;
        }
        if (pass.length < 8) {
            Swal.fire("Atención", "La contraseña debe tener al menos 8 caracteres.", "warning");
            return;
        }
        if (pass !== passConf) {
            Swal.fire("Error", "Las contraseñas no coinciden.", "error");
            return;
        }


        Swal.fire({
            title: "¿Deseas finalizar el registro?",
            icon: "question",
            showCancelButton: true,
            confirmButtonText: "Sí, registrar",
            cancelButtonText: "Cancelar"
        }).then((result) => {
            if (result.isConfirmed) {
                form.submit();
            }
        });

    });
});

