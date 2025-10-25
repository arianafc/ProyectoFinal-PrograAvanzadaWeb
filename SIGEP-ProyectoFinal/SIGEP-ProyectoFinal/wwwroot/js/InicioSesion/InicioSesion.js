document.addEventListener('DOMContentLoaded', function () {

    const toggle = document.querySelector('.toggle-password');
    const input = document.querySelector('.password-input');

    if (toggle && input) {
        toggle.addEventListener('click', function () {
            const type = input.type === 'password' ? 'text' : 'password';
            input.type = type;
            toggle.classList.toggle('fa-eye');
            toggle.classList.toggle('fa-eye-slash');
        });
    }


    $("#loginForm").on("submit", function (e) {
        e.preventDefault();

        let cedula = $("#cedulaLogin").val().trim();
        let contrasenna = $("#contrasenna").val().trim();

        if (!cedula || !contrasenna) {
            Swal.fire({
                icon: "warning",
                title: "Campos vacíos",
                text: "Por favor, completa ambos campos para continuar.",
                confirmButtonColor: "#2D594D"
            });
            return;
        }

        this.submit();
    });

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
});
