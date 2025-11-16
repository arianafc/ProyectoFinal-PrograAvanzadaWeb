$(function () {

    const errorElements = document.getElementsByClassName("TempError");
    const successElements = document.getElementsByClassName("TempSuccess");

    const errorMsg = errorElements.length > 0 ? errorElements[0].value : null;
    const successMsg = successElements.length > 0 ? successElements[0].value : null;

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
