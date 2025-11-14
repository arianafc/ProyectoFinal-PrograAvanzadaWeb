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


    $("#FechaNacimientoRegistro").datepicker({
        dateFormat: "yy-mm-dd",
        changeMonth: true,
        changeYear: true,
        yearRange: "1950:" + new Date().getFullYear(),
        maxDate: new Date(new Date().getFullYear() - 17, 11, 31), 
        defaultDate: new Date(new Date().getFullYear() - 17, 0, 1) 
    });

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
        let fechaNac = document.getElementById("FechaNacimientoRegistro").value.trim();
        let pass = document.getElementById("ContrasennaRegistro").value.trim();
        let passConf = document.getElementById("ContrasennaConfirmar").value.trim();

    
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

