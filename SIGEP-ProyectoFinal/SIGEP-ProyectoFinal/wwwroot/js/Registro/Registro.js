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


    $("#RegistroForm").on("submit", function (e) {
        e.preventDefault();

        const cedula = $("#CedulaRegistro").val();
        const nombre = $("#NombreRegistro").val();
        const apellido1 = $("#Apellido1Registro").val();
        const apellido2 = $("#Apellido2Registro").val();
        const especialidad = $("#EspecialidadRegistro").val();
        const fechaNacimiento = $("#FechaNacimientoRegistro").val();
        const contrasenna = $("#ContrasennaRegistro").val();
        const confirmar = $("#ContrasennaConfirmar").val();
        const seccion = $("#SeccionRegistro").val();
        const correo = $("#CorreoRegistro").val();

        if (!cedula || !nombre || !seccion || !apellido1 || !correo || !apellido2 || !especialidad || !fechaNacimiento || !contrasenna || !confirmar) {
            Swal.fire({
                icon: "warning",
                title: "Campos obligatorios",
                text: "Debes completar todos los campos antes de continuar.",
                confirmButtonColor: "#2D594D"
            });
            return;
        }

        if (contrasenna.length < 8) {
            Swal.fire({
                icon: "error",
                title: "Contraseña insegura",
                text: "La contraseña debe tener al menos 8 caracteres.",
                confirmButtonColor: "#2D594D"
            });
            return;
        }

        if (contrasenna !== confirmar) {
            Swal.fire({
                icon: "error",
                title: "Contraseñas no coinciden",
                text: "Asegúrate de que ambas contraseñas sean iguales.",
                confirmButtonColor: "#2D594D"
            });
            return;
        }

        this.submit();
    });

    $("#FechaNacimientoRegistro").datepicker({
        dateFormat: "yy-mm-dd",
        changeMonth: true,
        changeYear: true,
        yearRange: "1950:2025",
        defaultDate: "-18y"
    });


    document.querySelectorAll('.toggle-password').forEach(function (toggle) {
        toggle.addEventListener('click', function () {
            const input = this.previousElementSibling;

            if (input && input.classList.contains('password-input')) {
                const type = input.type === 'password' ? 'text' : 'password';
                input.type = type;

                this.classList.toggle('fa-eye');
                this.classList.toggle('fa-eye-slash');
            }
        });
    });


    $(".fa-calendar-alt").on("click", function () {
        $("#FechaNacimientoRegistro").focus();
    });
});

