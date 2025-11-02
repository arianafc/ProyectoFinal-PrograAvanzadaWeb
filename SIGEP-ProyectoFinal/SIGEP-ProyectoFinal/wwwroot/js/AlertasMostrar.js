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

});

